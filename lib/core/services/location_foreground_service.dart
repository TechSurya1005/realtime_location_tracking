import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';

class LocationForegroundService {
  LocationForegroundService._();
  static final LocationForegroundService instance =
      LocationForegroundService._();

  // ===================================================
  // 🚀 START SERVICE
  // ===================================================
  Future<void> start() async {
    final state = await bg.BackgroundGeolocation.state;
    if (state.enabled) return;

    bg.BackgroundGeolocation.onLocation(
      (bg.Location location) async {
        await _saveLocationToServer(location);
      },
      (error) {
        debugPrint('❌ BG location error: $error');
      },
    );

    bg.BackgroundGeolocation.onProviderChange((event) {
      debugPrint("📡 Provider enabled=${event.enabled}");
    });

    await bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 20,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        foregroundService: true,
        debug: false,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        heartbeatInterval: 60,
        notification: bg.Notification(
          title: 'Location Sharing Active',
          text: 'You are sharing your live location',
          channelName: 'Location Tracking',
          channelId: 'location_tracking',
          sticky: true,
          priority: bg.NotificationPriority.high,
        ),
      ),
    );

    await bg.BackgroundGeolocation.start();
  }

  // ===================================================
  // 🛑 STOP SERVICE
  // ===================================================
  Future<void> stop() async {
    await bg.BackgroundGeolocation.stop();
  }

  // ===================================================
  // ⏰ AUTO STOP TIME CHECK (23:00)
  // ===================================================
  static bool _isAfterStopTime() {
    final now = DateTime.now();
    return now.hour >= 23;
  }

  // ===================================================
  // 🔴 STOP LIVE SHARING
  // ===================================================
  static Future<void> _stopLiveSharing(
    SupabaseClient supabase,
    String authUid,
  ) async {
    final nowIso = DateTime.now().toIso8601String();

    await supabase
        .from('users')
        .update({
          'live_lat': null,
          'live_lng': null,
          'live_accuracy': null,
          'live_updated_at': nowIso,
          'is_live_sharing': false,
        })
        .eq('auth_uid', authUid);

    await bg.BackgroundGeolocation.stop();

    _lastLat = null;
    _lastLng = null;
    _lastGeocodeAt = null;
  }

  // ===================================================
  // 📍 CACHE
  // ===================================================
  static DateTime? _lastGeocodeAt;
  static double? _lastLat;
  static double? _lastLng;

  // ===================================================
  // 📡 SAVE LOCATION
  // ===================================================
  static Future<void> _saveLocationToServer(bg.Location location) async {
    final prefs = await SharedPreferences.getInstance();
    final authUid = prefs.getString(AppKeys.userAuthUid);
    if (authUid == null || authUid.isEmpty) return;

    final supabase = Supabase.instance.client;

    if (_isAfterStopTime()) {
      await _stopLiveSharing(supabase, authUid);
      return;
    }

    final nowIso = DateTime.now().toIso8601String();

    // -------------------------------
    // 📍 Reverse-geocode decision
    // -------------------------------
    bool shouldGeocode = false;

    if (_lastLat == null || _lastLng == null) {
      shouldGeocode = true;
    } else {
      final dist = Geolocator.distanceBetween(
        _lastLat!,
        _lastLng!,
        location.coords.latitude,
        location.coords.longitude,
      );
      if (dist > 50) shouldGeocode = true;
    }

    if (_lastGeocodeAt != null &&
        DateTime.now().difference(_lastGeocodeAt!).inMinutes < 5) {
      shouldGeocode = false;
    }

    String locality = '';
    String subLocality = '';
    String administrativeArea = '';
    String country = '';
    String postalCode = '';
    String fullAddress = '';

    if (shouldGeocode) {
      try {
        final placemarks = await placemarkFromCoordinates(
          location.coords.latitude,
          location.coords.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          locality = p.locality ?? '';
          subLocality = p.subLocality ?? '';
          administrativeArea = p.administrativeArea ?? '';
          country = p.country ?? '';
          postalCode = p.postalCode ?? '';

          fullAddress = [
            p.thoroughfare,
            subLocality,
            locality,
            administrativeArea,
            country,
          ].where((e) => e != null && e!.isNotEmpty).join(', ');
        }

        _lastGeocodeAt = DateTime.now();
      } catch (e) {
        debugPrint('❌ Geocoding failed: $e');
      }
    }

    _lastLat = location.coords.latitude;
    _lastLng = location.coords.longitude;

    // -------------------------------
    // 🧾 History
    // -------------------------------
    await supabase.from('location_history').insert({
      'user_auth_uid': authUid,
      'latitude': location.coords.latitude,
      'longitude': location.coords.longitude,
      'accuracy': location.coords.accuracy,
      'speed': location.coords.speed,
      'heading': location.coords.heading,
      'locality': locality,
      'sub_locality': subLocality,
      'administrative_area': administrativeArea,
      'country': country,
      'postal_code': postalCode,
      'full_address': fullAddress,
      'created_at': nowIso,
    });

    // -------------------------------
    // 📡 Live update
    // -------------------------------
    await supabase
        .from('users')
        .update({
          'live_lat': location.coords.latitude,
          'live_lng': location.coords.longitude,
          'live_accuracy': location.coords.accuracy,
          'live_updated_at': nowIso,
          'is_live_sharing': true,
        })
        .eq('auth_uid', authUid);
  }
}
