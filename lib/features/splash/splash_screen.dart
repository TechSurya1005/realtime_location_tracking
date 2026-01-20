import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realtime_location_tracking/app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppKeys.isLoggedIn) ?? false;

    if (isLoggedIn) {
      final role = prefs.getString(AppKeys.userRole);
      if (mounted) {
        if (role == 'admin') {
          context.goNamed(AppRouteNames.adminHome);
        } else {
          context.goNamed(AppRouteNames.home);
        }
      }
    } else {
      if (mounted) {
        context.goNamed(AppRouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Image.asset(
                "assets/images/bchlogo.png",
                height: 100,
                width: 100,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'BCH Marketing',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
