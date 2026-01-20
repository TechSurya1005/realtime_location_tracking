import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realtime_location_tracking/app/responsive/screen_type.dart';

/// Breakpoints based on modern device resolutions (2024-2025)
/// Mobile: 360-767px (phones including large/pro models)
/// Tablet: 768-1279px (tablets and small laptops)
/// Desktop: 1280px+ (laptops and desktop monitors)
class ScreenBreakpoints {
  // Mobile range: up to 767px
  // Covers: iPhone SE (375), standard phones (390-393), large phones (412-430)
  static const double mobileMax = 767;

  // Tablet range: 768px to 1279px
  // Covers: iPad (768), iPad Pro (820-1024), surface tablets (800-1180)
  static const double tabletMin = 768;
  static const double tabletMax = 1279;

  // Desktop range: 1280px and above
  // Covers: Laptops (1280-1536), Full HD (1920), 2K/4K displays
  static const double desktopMin = 1280;
}

class ResponsiveUtil {
  /// Get screen type using MediaQuery
  static ScreenType getScreenType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    return _getScreenTypeFromWidth(width);
  }

  /// Get screen type using LayoutBuilder constraints
  static ScreenType getScreenTypeFromConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    return _getScreenTypeFromWidth(width);
  }

  /// Internal method to determine screen type from width
  static ScreenType _getScreenTypeFromWidth(double width) {
    if (width <= ScreenBreakpoints.mobileMax) {
      return ScreenType.mobile;
    } else if (width >= ScreenBreakpoints.tabletMin &&
        width <= ScreenBreakpoints.tabletMax) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  /// Orientation helpers
  static bool isVerticalLayout(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isHorizontalLayout(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Context-based shortcuts
  static bool isMobile(BuildContext context) =>
      getScreenType(context) == ScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      getScreenType(context) == ScreenType.tablet;

  static bool isDesktop(BuildContext context) =>
      getScreenType(context) == ScreenType.desktop;

  static bool isWeb(BuildContext context) => kIsWeb;

  /// Get responsive padding based on screen type
  static double getHorizontalPadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 16.0;
      case ScreenType.tablet:
        return 32.0;
      case ScreenType.desktop:
        return 48.0;
      default:
        return 16.0; // Fallback to mobile padding
    }
  }

  /// Get responsive grid columns
  static int getGridColumns(
    BuildContext context, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobileColumns;
      case ScreenType.tablet:
        return tabletColumns;
      case ScreenType.desktop:
        return desktopColumns;
      default:
        return mobileColumns; // Fallback to mobile columns
    }
  }

  /// Get maximum content width for centered layouts
  static double getMaxContentWidth(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return double.infinity; // Full width on mobile
      case ScreenType.tablet:
        return 800; // Max width on tablet
      case ScreenType.desktop:
        return 1200; // Max width on desktop
      default:
        return double.infinity; // Fallback to full width
    }
  }

  /// Get responsive font scale factor
  static double getFontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width <= ScreenBreakpoints.mobileMax) {
      return 1.0; // Base size for mobile
    } else if (width <= ScreenBreakpoints.tabletMax) {
      return 1.1; // Slightly larger for tablet
    } else {
      return 1.2; // Larger for desktop
    }
  }
}

/// Extension for easier access to responsive utilities
extension ResponsiveContext on BuildContext {
  ScreenType get screenType => ResponsiveUtil.getScreenType(this);

  bool get isMobile => ResponsiveUtil.isMobile(this);

  bool get isTablet => ResponsiveUtil.isTablet(this);

  bool get isDesktop => ResponsiveUtil.isDesktop(this);

  bool get isPortrait => ResponsiveUtil.isVerticalLayout(this);

  bool get isLandscape => ResponsiveUtil.isHorizontalLayout(this);

  double get responsivePadding => ResponsiveUtil.getHorizontalPadding(this);

  double get maxContentWidth => ResponsiveUtil.getMaxContentWidth(this);
}