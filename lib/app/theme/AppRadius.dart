import 'package:flutter/material.dart';

class AppRadius {
  // === Extra Small Radius ===
  static const double xs = 2.0;
  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(2.0));
  static const BorderRadius xsTop = BorderRadius.vertical(top: Radius.circular(2.0));
  static const BorderRadius xsBottom = BorderRadius.vertical(bottom: Radius.circular(2.0));
  static const BorderRadius xsLeft = BorderRadius.horizontal(left: Radius.circular(2.0));
  static const BorderRadius xsRight = BorderRadius.horizontal(right: Radius.circular(2.0));

  // === Small Radius ===
  static const double sm = 4.0;
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius smTop = BorderRadius.vertical(top: Radius.circular(4.0));
  static const BorderRadius smBottom = BorderRadius.vertical(bottom: Radius.circular(4.0));
  static const BorderRadius smLeft = BorderRadius.horizontal(left: Radius.circular(4.0));
  static const BorderRadius smRight = BorderRadius.horizontal(right: Radius.circular(4.0));

  // === Medium Radius ===
  static const double md = 8.0;
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius mdTop = BorderRadius.vertical(top: Radius.circular(8.0));
  static const BorderRadius mdBottom = BorderRadius.vertical(bottom: Radius.circular(8.0));
  static const BorderRadius mdLeft = BorderRadius.horizontal(left: Radius.circular(8.0));
  static const BorderRadius mdRight = BorderRadius.horizontal(right: Radius.circular(8.0));

  // === Large Radius ===
  static const double lg = 12.0;
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius lgTop = BorderRadius.vertical(top: Radius.circular(12.0));
  static const BorderRadius lgBottom = BorderRadius.vertical(bottom: Radius.circular(12.0));
  static const BorderRadius lgLeft = BorderRadius.horizontal(left: Radius.circular(12.0));
  static const BorderRadius lgRight = BorderRadius.horizontal(right: Radius.circular(12.0));

  // === Extra Large Radius ===
  static const double xl = 16.0;
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius xlTop = BorderRadius.vertical(top: Radius.circular(16.0));
  static const BorderRadius xlBottom = BorderRadius.vertical(bottom: Radius.circular(16.0));
  static const BorderRadius xlLeft = BorderRadius.horizontal(left: Radius.circular(16.0));
  static const BorderRadius xlRight = BorderRadius.horizontal(right: Radius.circular(16.0));

  // === 2X Large Radius ===
  static const double xxl = 20.0;
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(20.0));
  static const BorderRadius xxlTop = BorderRadius.vertical(top: Radius.circular(20.0));
  static const BorderRadius xxlBottom = BorderRadius.vertical(bottom: Radius.circular(20.0));
  static const BorderRadius xxlLeft = BorderRadius.horizontal(left: Radius.circular(20.0));
  static const BorderRadius xxlRight = BorderRadius.horizontal(right: Radius.circular(20.0));

  // === 3X Large Radius ===
  static const double xxxl = 24.0;
  static const BorderRadius xxxlAll = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius xxxlTop = BorderRadius.vertical(top: Radius.circular(24.0));
  static const BorderRadius xxxlBottom = BorderRadius.vertical(bottom: Radius.circular(24.0));
  static const BorderRadius xxxlLeft = BorderRadius.horizontal(left: Radius.circular(24.0));
  static const BorderRadius xxxlRight = BorderRadius.horizontal(right: Radius.circular(24.0));

  // === 4X Large Radius (Pill/Capsule) ===
  static const double xxxxl = 32.0;
  static const BorderRadius xxxxlAll = BorderRadius.all(Radius.circular(32.0));
  static const BorderRadius xxxxlTop = BorderRadius.vertical(top: Radius.circular(32.0));
  static const BorderRadius xxxxlBottom = BorderRadius.vertical(bottom: Radius.circular(32.0));
  static const BorderRadius xxxxlLeft = BorderRadius.horizontal(left: Radius.circular(32.0));
  static const BorderRadius xxxxlRight = BorderRadius.horizontal(right: Radius.circular(32.0));

  // === Circular/Full Radius ===
  static const double full = 50.0;
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(50.0));

  // === Special Purpose Radius ===
  static const double card = 12.0;
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(12.0));

  static const double button = 25.0;
  static const BorderRadius buttonAll = BorderRadius.all(Radius.circular(25.0));

  static const double fab = 16.0;
  static const BorderRadius fabAll = BorderRadius.all(Radius.circular(16.0));

  static const double chip = 20.0;
  static const BorderRadius chipAll = BorderRadius.all(Radius.circular(20.0));

  static const double dialog = 20.0;
  static const BorderRadius dialogAll = BorderRadius.all(Radius.circular(20.0));

  static const double sheet = 24.0;
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(24.0));

  static const double avatar = 100.0;
  static const BorderRadius avatarAll = BorderRadius.all(Radius.circular(100.0));

  // === Responsive Radius Methods ===
  static double responsiveRadius(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1024) return desktop;
    if (width > 600) return tablet;
    return mobile;
  }

  static BorderRadius responsiveBorderRadius(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    return BorderRadius.circular(responsiveRadius(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    ));
  }
}