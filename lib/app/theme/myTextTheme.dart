import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'AppColors.dart';

class MyTextTheme {
  MyTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    displayLarge: _style(AppColors.text, 96.0, FontWeight.w100), // Thin
    displayMedium: _style(AppColors.text, 60.0, FontWeight.w300), // Light
    displaySmall: _style(AppColors.text, 48.0, FontWeight.w400), // Regular
    headlineMedium: _style(AppColors.text, 34.0, FontWeight.w500), // Medium
    headlineSmall: _style(AppColors.text, 24.0, FontWeight.w500),
    titleLarge: _style(AppColors.text, 20.0, FontWeight.w500),
    titleMedium: _style(AppColors.text, 16.0, FontWeight.w400),
    titleSmall: _style(AppColors.text, 14.0, FontWeight.w500),
    bodyLarge: _style(AppColors.text, 16.0, FontWeight.w400),
    bodyMedium: _style(AppColors.text, 14.0, FontWeight.w400),
    bodySmall: _style(AppColors.text, 12.0, FontWeight.w400),
    labelLarge: _style(AppColors.text, 14.0, FontWeight.w500),
    labelMedium: _style(AppColors.text, 12.0, FontWeight.w500),
    labelSmall: _style(AppColors.text, 10.0, FontWeight.w400),
  );

  static TextTheme darkTextTheme = TextTheme(
    displayLarge: _style(AppColors.textDark, 96.0, FontWeight.w100),
    displayMedium: _style(AppColors.textDark, 60.0, FontWeight.w300),
    displaySmall: _style(AppColors.textDark, 48.0, FontWeight.w400),
    headlineMedium: _style(AppColors.textDark, 34.0, FontWeight.w500),
    headlineSmall: _style(AppColors.textDark, 24.0, FontWeight.w500),
    titleLarge: _style(AppColors.textDark, 20.0, FontWeight.w500),
    titleMedium: _style(AppColors.textDark, 16.0, FontWeight.w400),
    titleSmall: _style(AppColors.textDark, 14.0, FontWeight.w500),
    bodyLarge: _style(AppColors.textDark, 16.0, FontWeight.w400),
    bodyMedium: _style(AppColors.textDark, 14.0, FontWeight.w400),
    bodySmall: _style(AppColors.textDark, 12.0, FontWeight.w400),
    labelLarge: _style(AppColors.textDark, 14.0, FontWeight.w500),
    labelMedium: _style(AppColors.textDark, 12.0, FontWeight.w500),
    labelSmall: _style(AppColors.textDark, 10.0, FontWeight.w400),
  );

  static TextStyle _style(
    Color color,
    double size, [
    FontWeight weight = FontWeight.normal,
    FontStyle style = FontStyle.normal,
  ]) {
    return TextStyle(
      fontFamily: "Poppins",
      color: color,
      fontSize: size.sp,
      fontWeight: weight,
      fontStyle: style,
      letterSpacing: 0.0,
    );
  }
}
