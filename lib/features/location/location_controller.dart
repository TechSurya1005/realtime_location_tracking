import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'package:realtime_location_tracking/app/constants/AppTexts.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';
import 'package:realtime_location_tracking/core/services/location_service.dart';

// =====================================================
// 🔥 TOP LEVEL AUTO STOP CALLBACK (BACKGROUND)
// =====================================================
@pragma('vm:entry-point')
void autoStopCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    final prefs = await SharedPreferences.getInstance();
    final authUid = prefs.getString(AppKeys.userAuthUid);
    if (authUid == null) return;

    await Supabase.initialize(
      url: AppText.supbaseDatabaseUrl,
      anonKey: AppText.supbaseDatabaseAnonKey,
    );

    final supabase = Supabase.instance.client;

    await supabase
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

    await LocationService.instance.stopLiveShare();
    await AndroidAlarmManager.cancel(0);

    debugPrint('🛑 Auto-stop executed');
  } catch (e) {
    debugPrint('❌ Auto-stop error: $e');
  }
}

// =====================================================
// 📍 LOCATION CONTROLLER
// =====================================================
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
  // 🔐 PERMISSION HANDLER (FIXED)
  // =====================================================
  Future<LocationPermission> _handlePermission(BuildContext context) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return permission;
    }

    if (permission == LocationPermission.whileInUse) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Background location required'),
          content: const Text(
            'Live tracking works in foreground.\n\n'
            'For background tracking, allow location access "All the time" from settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }

    return permission;
  }

  // =====================================================
  // ▶️ FOREGROUND TRACKING
  // =====================================================
  void _startForegroundTracking() {
    if (_foregroundSubscription != null) return;

    debugPrint('▶️ Foreground tracking started');

    _foregroundSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // CHANGED: 5 -> 20 meter
      ),
    ).listen(saveLiveShareLocation);
  }

  void _stopForegroundTracking() {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
    debugPrint('⏹ Foreground tracking stopped');
  }

  // =====================================================
  // 🔥 START LIVE SHARE (MAIN ENTRY)
  // =====================================================
  Future<void> startLiveShare(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authUid = prefs.getString(AppKeys.userAuthUid);
      if (authUid == null) return;

      final permission = await _handlePermission(context);

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _startForegroundTracking();

      final bool allowBackground = permission == LocationPermission.always;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final now = DateTime.now();
      DateTime stopAt = DateTime(now.year, now.month, now.day, 23);
      if (stopAt.isBefore(now)) {
        stopAt = stopAt.add(const Duration(days: 1));
      }

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

      if (allowBackground) {
        await AndroidAlarmManager.initialize();
        await AndroidAlarmManager.cancel(0);
        await AndroidAlarmManager.oneShotAt(
          stopAt,
          0,
          autoStopCallback,
          exact: true,
          wakeup: true,
        );

        await LocationService.instance.startLiveShareFullDay();
        debugPrint('✅ Background tracking enabled');
      } else {
        debugPrint('ℹ️ Foreground-only tracking');
      }
    } catch (e) {
      debugPrint('❌ startLiveShare error: $e');
    }
  }

  // =====================================================
  // 📡 LOCATION UPDATE ENTRY (FG + BG)
  // =====================================================
  Future<void> saveLiveShareLocation(Position position) async {
    try {
      if (position.accuracy > 10) return;

      final now = DateTime.now();

      if (_lastSavedTime != null &&
          now.difference(_lastSavedTime!).inSeconds < 10)
        return;

      if (_lastSavedPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastSavedPosition!.latitude,
          _lastSavedPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < 20) return; // CHANGED: 3 -> 20 meter
      }

      final prefs = await SharedPreferences.getInstance();
      final authUid = prefs.getString(AppKeys.userAuthUid);
      if (authUid == null) return;

      // ✅ UPDATE LIVE LOCATION (EVERY MOVEMENT)
      await _supabase
          .from('users')
          .update({
            'live_lat': position.latitude,
            'live_lng': position.longitude,
            'live_accuracy': position.accuracy,
            'live_updated_at': now.toIso8601String(),
            'is_live_sharing': true,
          })
          .eq('auth_uid', authUid);

      // ✅ UPDATE HISTORY (ONLY FIRST & LAST OF DAY)
      await _updateHistoryOnlyFirstAndLast(authUid, position);

      _lastSavedPosition = position;
      _lastSavedTime = now;
      _lat = position.latitude;
      _lng = position.longitude;
      _accuracy = position.accuracy;
      notifyListeners();

      debugPrint('📍 Location updated');
    } catch (e) {
      debugPrint('❌ saveLiveShareLocation error: $e');
    }
  }

  bool _isPlusCode(String? s) {
    if (s == null || s.isEmpty) return false;
    return s.contains('+') && s.length < 15;
  }

  /// Saves or updates location history to keep only the first and last record of the day.
  Future<void> _updateHistoryOnlyFirstAndLast(
    String authUid,
    Position position,
  ) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final startOfDay = '${today}T00:00:00Z';
      final endOfDay = '${today}T23:59:59Z';

      // 1. Get placemark details for full address info
      String locality = '';
      String subLocality = '';
      String administrativeArea = '';
      String country = '';
      String postalCode = '';
      String fullAddress = '';

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark p = placemarks.first;
          locality = p.locality ?? '';
          subLocality = p.subLocality ?? '';
          administrativeArea = p.administrativeArea ?? '';
          country = p.country ?? '';
          postalCode = p.postalCode ?? '';

          final addressParts = <String>[];
          String streetName = p.thoroughfare ?? '';
          if (streetName.isEmpty || _isPlusCode(streetName)) {
            if (!_isPlusCode(p.name)) {
              streetName = p.name ?? '';
            } else {
              streetName = '';
            }
          }

          if (streetName.isNotEmpty) addressParts.add(streetName);
          if (subLocality.isNotEmpty) addressParts.add(subLocality);
          if (locality.isNotEmpty) addressParts.add(locality);
          if (administrativeArea.isNotEmpty) {
            addressParts.add(administrativeArea);
          }
          if (country.isNotEmpty) addressParts.add(country);

          fullAddress = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        debugPrint('⚠️ Geocoding error in history: $e');
      }

      // 2. Get history records for today
      final history = await _supabase
          .from('location_history')
          .select('id')
          .eq('user_auth_uid', authUid)
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay)
          .order('created_at', ascending: true);

      final data = {
        'user_auth_uid': authUid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'locality': locality,
        'sub_locality': subLocality,
        'administrative_area': administrativeArea,
        'country': country,
        'postal_code': postalCode,
        'full_address': fullAddress,
      };

      if (history.isEmpty || history.length == 1) {
        // First or Second record of the day
        await _supabase.from('location_history').insert(data);
        debugPrint(
          '📜 History: ${history.isEmpty ? 'First' : 'Last'} record inserted',
        );
      } else {
        // Update the "last" record of the day
        final lastId = history.last['id'];
        await _supabase
            .from('location_history')
            .update({...data, 'created_at': DateTime.now().toIso8601String()})
            .eq('id', lastId);
        debugPrint('📜 History: Last record updated');
      }
    } catch (e) {
      debugPrint('❌ _updateHistoryOnlyFirstAndLast error: $e');
    }
  }

  // =====================================================
  // 🛑 STOP EVERYTHING
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
    _stopForegroundTracking();
    await LocationService.instance.stopLiveShare();
    await AndroidAlarmManager.cancel(0);

    notifyListeners();
  }
}
