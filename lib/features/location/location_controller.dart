import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:realtime_location_tracking/core/services/location_foreground_service.dart';
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

  Position? _lastSavedPosition;
  DateTime? _lastSavedTime;

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

    if (permission == LocationPermission.whileInUse) {
      // Ask user to allow "All time"
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Allow Background Location'),
          content: const Text(
            'To share live location even when the app is closed or not in use, '
            'please set location permission to "Allow all the time" in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Not Now'),
            ),
          ],
        ),
      );
    }

    return true;
  }

  // =====================================================
  // ▶️ FOREGROUND TRACKING (APP OPEN)
  // =====================================================
  void _startForegroundTracking() {
    if (_foregroundSubscription != null) return;

    _foregroundSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen(saveLiveShareLocation);
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

    // Start local foreground subscription
    _startForegroundTracking();

    // Start service for background
    await LocationForegroundService.instance.start();
  }

  // =====================================================
  // 📡 LOCATION UPDATE (APP & SERVICE UPDATED)
  // =====================================================
  Future<void> saveLiveShareLocation(Position position) async {
    try {
      if (position.accuracy > 25) return;

      final now = DateTime.now();
      if (_lastSavedTime != null &&
          now.difference(_lastSavedTime!).inSeconds < 10)
        return;

      if (_lastSavedPosition != null) {
        final dist = Geolocator.distanceBetween(
          _lastSavedPosition!.latitude,
          _lastSavedPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (dist < 20) return;
      }

      final prefs = await SharedPreferences.getInstance();
      final authUid = prefs.getString(AppKeys.userAuthUid);
      if (authUid == null) return;

      // UPDATE MAIN USERS TABLE
      await _supabase
          .from('users')
          .update({
            'live_lat': position.latitude,
            'live_lng': position.longitude,
            'live_accuracy': position.accuracy,
            'live_updated_at': now.toIso8601String(),
          })
          .eq('auth_uid', authUid);

      // INSERT HISTORY
      await _supabase.from('location_history').insert({
        'user_auth_uid': authUid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'full_address': '', // you can add geocoding if needed
      });

      _lastSavedPosition = position;
      _lastSavedTime = now;

      _lat = position.latitude;
      _lng = position.longitude;
      _accuracy = position.accuracy;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ saveLiveShareLocation error: $e');
    }
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
    await LocationForegroundService.instance.stop();
  }
}
