import 'package:flutter/foundation.dart';
import 'package:realtime_location_tracking/app/constants/AppKeys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isDark = false;

  ThemeNotifier(SharedPreferences prefs) {
    _prefs = prefs;
    _isDark = _prefs.getBool(AppKeys.appTheme) ?? false;
  }

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    _prefs.setBool(AppKeys.appTheme, _isDark);
    notifyListeners();
  }
}
