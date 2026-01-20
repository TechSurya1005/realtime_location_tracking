import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:realtime_location_tracking/app/responsive/ResponsiveUtil.dart';
import 'package:realtime_location_tracking/app/responsive/screen_type.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';
import 'package:realtime_location_tracking/app/theme/themeExtension.dart';

class AppTextStyle {
  // Responsive font size calculator using your ResponsiveUtil
  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final screenType = ResponsiveUtil.getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile.sp;
      case ScreenType.tablet:
        return tablet.sp;
      case ScreenType.desktop:
        return desktop.sp;
      default:
        return mobile.sp;
    }
  }

  // Font scale multiplier for additional responsiveness
  static double _getFontScale(BuildContext context) {
    return ResponsiveUtil.getFontScale(context);
  }

  // Display Styles (Large headlines)
  static TextStyle displayLargeStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 96,
      tablet: 112,
      desktop: 128,
    );

    return TextStyle(
      fontWeight: FontWeight.w300,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),

      letterSpacing: -1.5,
    );
  }

  static TextStyle displayMediumStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 60,
      tablet: 72,
      desktop: 84,
    );

    return TextStyle(
      fontWeight: FontWeight.w300,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),

      letterSpacing: -0.5,
    );
  }

  static TextStyle displaySmallStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 48,
      tablet: 56,
      desktop: 64,
    );

    return TextStyle(
      fontWeight: FontWeight.w400,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
      letterSpacing: 0.0,
    );
  }

  // Headline Styles (Page titles)
  static TextStyle headlineMediumStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 34,
      tablet: 40,
      desktop: 48,
    );

    return TextStyle(
      fontWeight: FontWeight.w400,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
      letterSpacing: 0.25,
    );
  }

  static TextStyle headlineSmallStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 24,
      tablet: 28,
      desktop: 32,
    );

    return TextStyle(
      fontWeight: FontWeight.w400,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
      letterSpacing: 0.0,
    );
  }

  // Title Styles (Section headings)
  static TextStyle titleLargeStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 20,
      tablet: 22,
      desktop: 24,
    );

    return TextStyle(
      fontWeight: FontWeight.w500,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
      letterSpacing: 0.15,
    );
  }

  static TextStyle titleMediumStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 18,
      tablet: 18,
      desktop: 20,
    );

    return TextStyle(
      fontWeight: FontWeight.w500,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  static TextStyle titleSmallStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 14,
      tablet: 15,
      desktop: 16,
    );

    return TextStyle(
      fontWeight: FontWeight.w500,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  // Body Styles (Main content)
  static TextStyle bodyLargeStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 16,
      tablet: 17,
      desktop: 18,
    );

    return TextStyle(
      fontWeight: FontWeight.w400,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  static TextStyle bodyMediumStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 14,
      tablet: 15,
      desktop: 16,
    );

    return TextStyle(
      fontWeight: FontWeight.w400,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  static TextStyle bodySmallStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 12,
      tablet: 13,
      desktop: 14,
    );

    return TextStyle(
      fontWeight: FontWeight.w400,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  // Label Styles (Buttons, captions)
  static TextStyle labelLargeStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
    );

    return TextStyle(
      fontWeight: FontWeight.w500,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  static TextStyle labelMediumStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 14,
      tablet: 16,
      desktop: 18,
    );

    return TextStyle(
      fontWeight: FontWeight.w500,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  static TextStyle labelSmallStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 12,
      tablet: 11,
      desktop: 12,
    );

    return TextStyle(
      fontWeight: FontWeight.w500,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  // Additional utility styles for common use cases
  static TextStyle buttonStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 16,
      tablet: 17,
      desktop: 18,
    );

    return TextStyle(
      fontWeight: FontWeight.w600,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  static TextStyle captionStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 11,
      tablet: 12,
      desktop: 13,
    );

    return TextStyle(
      fontWeight: FontWeight.w400,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  static TextStyle overlineStyle(BuildContext context) {
    final baseSize = responsiveFontSize(
      context,
      mobile: 9,
      tablet: 10,
      desktop: 11,
    );

    return TextStyle(
      fontWeight: FontWeight.w500,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
    );
  }

  // Helper method for custom responsive text
  static TextStyle customStyle(
    BuildContext context, {
    required double mobileSize,
    required double tabletSize,
    required double desktopSize,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) {
    final baseSize = responsiveFontSize(
      context,
      mobile: mobileSize,
      tablet: tabletSize,
      desktop: desktopSize,
    );

    return TextStyle(
      fontWeight: fontWeight,
      color: context.isDarkTheme ? AppColors.textDark : AppColors.text,
      fontSize: baseSize * _getFontScale(context),
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
