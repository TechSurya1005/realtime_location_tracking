import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:realtime_location_tracking/app/constants/AppTexts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:realtime_location_tracking/app/routes/app_go_router.dart';
import 'package:realtime_location_tracking/app/theme/themController.dart';
import 'package:realtime_location_tracking/app/theme/theme.dart';

import 'package:realtime_location_tracking/features/home/home_controller.dart';
import 'package:realtime_location_tracking/features/auth/auth_controller.dart';
import 'package:realtime_location_tracking/features/admin/admin_controller.dart';
import 'package:realtime_location_tracking/features/location/location_controller.dart';
import 'package:realtime_location_tracking/features/admin/location_history_controller.dart';
import 'package:realtime_location_tracking/features/profile/profile_controller.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';

@pragma('vm:entry-point')
void backgroundGeolocationHeadlessTask(bg.HeadlessEvent event) async {
  if (event.name != bg.Event.LOCATION) return;

  final bg.Location location = event.event;

  await Supabase.initialize(
    url: AppText.supbaseDatabaseUrl,
    anonKey: AppText.supbaseDatabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final authUid = prefs.getString(AppKeys.userAuthUid);
  if (authUid == null || authUid.isEmpty) return;

  final supabase = Supabase.instance.client;
  final nowIso = DateTime.now().toIso8601String();

  // ⚠️ Minimal geocoding in headless
  String fullAddress = '';

  try {
    final placemarks = await placemarkFromCoordinates(
      location.coords.latitude,
      location.coords.longitude,
    );
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      fullAddress = [
        p.thoroughfare,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ].where((e) => e != null && e!.isNotEmpty).join(', ');
    }
  } catch (_) {}

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

  await supabase.from('location_history').insert({
    'user_auth_uid': authUid,
    'latitude': location.coords.latitude,
    'longitude': location.coords.longitude,
    'accuracy': location.coords.accuracy,
    'speed': location.coords.speed,
    'heading': location.coords.heading,
    'full_address': fullAddress,
    'created_at': nowIso,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 CREATE CHANNEL FIRST
  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_tracking',
      'Location Tracking',
      description: 'Foreground service for location tracking',
      importance: Importance.low,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  bg.BackgroundGeolocation.registerHeadlessTask(
    backgroundGeolocationHeadlessTask,
  );

  await Supabase.initialize(
    url: AppText.supbaseDatabaseUrl,
    anonKey: AppText.supbaseDatabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(prefs),
        ),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => LocationController()),
        ChangeNotifierProvider(create: (_) => LocationHistoryController()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: 'BCH Marketing',
                routerConfig: AppGoRouter.router,
                debugShowCheckedModeBanner: false,
                theme: MyTheme.lightTheme(context),
                darkTheme: MyTheme.darkTheme(context),
                themeMode: themeNotifier.isDark
                    ? ThemeMode.dark
                    : ThemeMode.light,
              );
            },
          );
        },
      ),
    );
  }
}
