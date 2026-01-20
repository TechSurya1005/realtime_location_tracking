import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:realtime_location_tracking/features/location/location_controller.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  StreamSubscription<Position>? _foregroundSub;

  // =====================================================
  // ✅ FOREGROUND LOCATION (APP OPEN MODE)
  // =====================================================
  Future<void> startForegroundLocation({
    required int minDistanceMeters,
    required void Function(
      Position position,
      String? address,
      dynamic placemark,
    )
    onUpdate,
  }) async {
    await stopForegroundLocation();

    _foregroundSub =
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: minDistanceMeters,
            intervalDuration: const Duration(seconds: 5),
          ),
        ).listen((position) {
          onUpdate(position, null, null);
        });
  }

  Future<void> stopForegroundLocation() async {
    await _foregroundSub?.cancel();
    _foregroundSub = null;
  }

  // =====================================================
  // 🔥 LIVE SHARE START (BACKGROUND)
  // =====================================================
  Future<void> startLiveShareFullDay() async {
    final service = FlutterBackgroundService();

    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }

    service.invoke('startLiveShare');
  }

  // =====================================================
  // 🛑 STOP LIVE SHARE
  // =====================================================
  Future<void> stopLiveShare() async {
    final service = FlutterBackgroundService();
    try {
      service.invoke('stopLiveShare');
    } catch (_) {}
  }

  // =====================================================
  // 🔐 PERMISSION
  // =====================================================
  static Future<bool> _permission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var p = await Permission.locationAlways.status;
    if (!p.isGranted) {
      p = await Permission.locationAlways.request();
    }
    return p.isGranted;
  }

  // =====================================================
  // 🔄 BACKGROUND ENGINE
  // =====================================================
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: 'Live location sharing',
        content: 'Sharing live location',
      );
    }

    if (!await _permission()) {
      service.stopSelf();
      return;
    }

    bool liveShareEnabled = false;
    bool initialSnapshotSaved = false;
    Position? lastPosition;

    final supabase = Supabase.instance.client;

    // 🔒 SAFETY CHECK ON START (DB IS AUTHORITY)
    try {
      final prefs = await SharedPreferences.getInstance();
      final authUid = prefs.getString(AppKeys.userAuthUid);

      if (authUid != null) {
        final data = await supabase
            .from('users')
            .select('is_live_sharing')
            .eq('auth_uid', authUid)
            .single();

        if (data['is_live_sharing'] != true) {
          service.stopSelf();
          return;
        }
      }
    } catch (_) {}

    // ▶️ START LIVE SHARE
    service.on('startLiveShare').listen((_) {
      liveShareEnabled = true;
      initialSnapshotSaved = false;
    });

    // ⏹️ STOP LIVE SHARE
    service.on('stopLiveShare').listen((_) {
      liveShareEnabled = false;
      service.stopSelf();
    });

    final controller = LocationController();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // CHANGED: 10 -> 20 meter
      ),
    ).listen((position) async {
      if (!liveShareEnabled) return;

      final prefs = await SharedPreferences.getInstance();
      final authUid = prefs.getString(AppKeys.userAuthUid);
      if (authUid == null) return;

      // 🔥 AUTO STOP TIME CHECK (SAFE PLACE)
      try {
        final data = await supabase
            .from('users')
            .select('is_live_sharing, live_stop_at')
            .eq('auth_uid', authUid)
            .single();

        if (data['is_live_sharing'] != true) {
          service.stopSelf();
          return;
        }

        final stopAt = DateTime.parse(data['live_stop_at']);
        if (DateTime.now().isAfter(stopAt)) {
          // 🛑 STOP
          await supabase
              .from('users')
              .update({
                'is_live_sharing': false,
                'live_lat': null,
                'live_lng': null,
                'live_accuracy': null,
                'live_updated_at': DateTime.now().toIso8601String(),
              })
              .eq('auth_uid', authUid);

          service.stopSelf();
          return;
        }
      } catch (_) {}

      // ✅ INITIAL SNAPSHOT
      if (!initialSnapshotSaved) {
        initialSnapshotSaved = true;
        await controller.saveLiveShareLocation(position);
        return;
      }

      // ✅ MOVEMENT CHECK
      if (lastPosition != null) {
        final moved = Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (moved < 20) return; // CHANGED: 10 -> 20 meter
      }

      lastPosition = position;
      await controller.saveLiveShareLocation(position);
    });
  }
}
