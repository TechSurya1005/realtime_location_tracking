import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
