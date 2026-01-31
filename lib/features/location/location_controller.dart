import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:realtime_location_tracking/core/services/native_location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';

class LocationController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  double? _lat;
  double? _lng;
  double? _accuracy;

  bool _liveShareRunning = false;

  double? get lat => _lat;
  double? get lng => _lng;
  double? get accuracy => _accuracy;
  bool get liveShareRunning => _liveShareRunning;

  StreamSubscription<Position>? _foregroundSubscription;

  // =====================================================
  // 🔐 PERMISSION HANDLER
  // =====================================================
  Future<bool> _checkPermission(BuildContext context) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // Android 10+ needs 'Always Allow' for background location to work reliably
    // although our Foreground Service bypasses some of this, 'Always Allow' is best for Resume.
    if (Platform.isAndroid && permission == LocationPermission.whileInUse) {
      // We can guide them, but Foreground Service works with WhileInUse as long as it starts when app is visible.
      // However, for maximum durability ("Uber-like"), Always is preferred.
    }

    return true;
  }

  // =====================================================
  // ▶️ FOREGROUND TRACKING (APP OPEN)
  // =====================================================
  void _startForegroundTracking() {
    if (_foregroundSubscription != null) return;

    // We still keep a foreground listener to update best-effort UI instantly
    _foregroundSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 10,
          ),
        ).listen((position) {
          _lat = position.latitude;
          _lng = position.longitude;
          _accuracy = position.accuracy;
          notifyListeners();
          // We DO NOT save to DB here to avoid double-writes with Native Service
          // Native Service is the "Source of Truth" for DB.
          // OR: We can save if we want faster updates when open.
          // Let's rely on Native Service for consistent history to avoid duplicates.
        });
  }

  void _stopForegroundTracking() {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }

  // =====================================================
  // 🔥 START LIVE SHARE ENTRY
  // =====================================================
  Future<void> startLiveShare(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final authUid = prefs.getString(AppKeys.userAuthUid);
    if (authUid == null) return;

    final allowed = await _checkPermission(context);
    if (!allowed) return;

    // 🔋 REQUEST BATTERY OPTIMIZATION IGNORE (Critical for long running bg service)
    if (Platform.isAndroid) {
      final batteryStatus = await Permission.ignoreBatteryOptimizations
          .request();
      if (batteryStatus.isDenied) {
        debugPrint(
          "User denied battery optimization ignore. Service might be killed.",
        );
        // Optional: Show dialog explaining why
      }
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final now = DateTime.now();
    // Stop at end of day
    DateTime stopAt = DateTime(now.year, now.month, now.day, 23, 59, 59);

    await _supabase
        .from('users')
        .update({
          'is_live_sharing': true,
          'live_started_at': now.toIso8601String(),
          'live_stop_at': stopAt.toIso8601String(),
          'live_updated_at': now.toIso8601String(),
          'live_lat': pos.latitude,
          'live_lng': pos.longitude,
          'live_accuracy': pos.accuracy,
        })
        .eq('auth_uid', authUid);

    _liveShareRunning = true;
    notifyListeners();

    // Start local foreground subscription for UI
    _startForegroundTracking();

    // 🚀 START NATIVE SERVICE (The Real Deal)
    await NativeLocationService.start();
  }

  // =====================================================
  // 🛑 STOP LIVE SHARE
  // =====================================================
  Future<void> stopLiveShareManually() async {
    final prefs = await SharedPreferences.getInstance();
    final authUid = prefs.getString(AppKeys.userAuthUid);
    if (authUid == null) return;

    await _supabase
        .from('users')
        .update({
          'is_live_sharing': false,
          'live_lat': null,
          'live_lng': null,
          'live_accuracy': null,
          'live_stop_at': null,
          'live_started_at': null,
          'live_updated_at': DateTime.now().toIso8601String(),
        })
        .eq('auth_uid', authUid);

    _liveShareRunning = false;
    notifyListeners();

    _stopForegroundTracking();

    // 🛑 STOP NATIVE SERVICE
    await NativeLocationService.stop();
  }
}
