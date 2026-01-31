import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';
import 'package:realtime_location_tracking/app/constants/AppTexts.dart';

// ==========================================
// 💀 HEADLESS ENTRY POINT
// ==========================================
@pragma('vm:entry-point')
void nativeLocationHeadlessTask() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the MethodChannel to receive data from Kotlin
  const channel = MethodChannel('com.bch/location_updates');

  channel.setMethodCallHandler((call) async {
    if (call.method == 'onLocation') {
      try {
        final args = call.arguments as Map;
        final double? lat = args['lat'];
        final double? lng = args['lng'];
        final double? speed = args['speed']; // speed in m/s

        if (lat == null || lng == null) return;

        // Initialize Supabase if needed
        // We do this every time or check if initialized, as this isolate might be fresh
        try {
          // Supabase.initialize throws if already initialized, which is fine
          // We catch the error below
          await Supabase.initialize(
            url: AppText.supbaseDatabaseUrl,
            anonKey: AppText.supbaseDatabaseAnonKey,
          );
        } catch (_) {
          // Already initialized or concurrent access
        }

        // Get User UID from SharedPrefs (Native stores it as part of 'flutter.' prefix namespace)
        // Note: SharedPreferences.getInstance() reads from disk, so it works across isolates.
        final prefs = await SharedPreferences.getInstance();
        final authUid = prefs.getString(AppKeys.userAuthUid);

        if (authUid == null || authUid.isEmpty) {
          debugPrint("NativeLocationService: No Auth UID found in prefs");
          return;
        }

        final nowIso = DateTime.now().toIso8601String();
        final supabase = Supabase.instance.client;

        // Optional: Simple Geocoding (Throttle to avoid API limits if necessary)
        // For now, minimal implementation
        String fullAddress = '';
        try {
          // You might want to skip geocoding in background to save battery/quota
          // or throttle it. Keeping it simple here as requested.
        } catch (_) {}

        // Update Live Location
        await supabase
            .from('users')
            .update({
              'live_lat': lat,
              'live_lng': lng,
              'live_accuracy': 10, // Approximate from Native
              'live_updated_at': nowIso,
              'is_live_sharing': true,
              // 'speed': speed, // Add if table has column
            })
            .eq('auth_uid', authUid);

        // Save History
        await supabase.from('location_history').insert({
          'user_auth_uid': authUid,
          'latitude': lat,
          'longitude': lng,
          'accuracy': 10, // Approximate
          'speed': speed,
          'heading':
              0.0, // Unavailable in this simple payload, update native if needed
          'full_address': fullAddress,
          'created_at': nowIso,
        });

        debugPrint("NativeLocationService: Uploaded $lat, $lng");
      } catch (e) {
        debugPrint("NativeLocationService Error: $e");
      }
    } else if (call.method == 'onServiceStopped') {
      try {
        // Initialize Supabase if needed (same safety check)
        try {
          await Supabase.initialize(
            url: AppText.supbaseDatabaseUrl,
            anonKey: AppText.supbaseDatabaseAnonKey,
          );
        } catch (_) {}

        final prefs = await SharedPreferences.getInstance();
        final authUid = prefs.getString(AppKeys.userAuthUid);

        if (authUid != null) {
          final supabase = Supabase.instance.client;
          await supabase
              .from('users')
              .update({
                'is_live_sharing': false,
                'live_lat': null, // Optional: clear location or keep last known
                'live_lng': null,
                'live_updated_at': DateTime.now().toIso8601String(),
              })
              .eq('auth_uid', authUid);

          debugPrint(
            "NativeLocationService: Marked user as offline (stopped).",
          );
        }
      } catch (e) {
        debugPrint("NativeLocationService: Error handling stop event: $e");
      }
    }
  });
}

class NativeLocationService {
  static const MethodChannel _channel = MethodChannel(
    'com.bch/location_control',
  );

  /// Starts the Native Service
  static Future<void> start() async {
    // 1. Get Callback Handle for the Headless Task
    final CallbackHandle? callback = PluginUtilities.getCallbackHandle(
      nativeLocationHeadlessTask,
    );
    if (callback == null) {
      debugPrint(
        "NativeLocationService: Fatal Error - Cannot find callback handle",
      );
      return;
    }

    final int handleId = callback.toRawHandle();

    // 2. Save state for Native Service to read
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking_enabled', true);
    await prefs.setInt('location_callback_id', handleId);

    // Ensure we have the UID saved for the headless task to pick up later
    final authUid = prefs.getString(AppKeys.userAuthUid);
    if (authUid == null) {
      debugPrint("NativeLocationService: Warning - No User UID in prefs!");
    }

    // 3. Command Native Service to Start
    try {
      await _channel.invokeMethod('startService');
    } catch (e) {
      debugPrint("NativeLocationService: Failed to start native service: $e");
    }
  }

  /// Stops the Native Service
  static Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking_enabled', false);

    try {
      await _channel.invokeMethod('stopService');
    } catch (e) {
      debugPrint("NativeLocationService: Failed to stop native service: $e");
    }
  }
}
