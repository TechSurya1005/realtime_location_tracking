import 'package:flutter/material.dart';

class AppColors {
  // === Primary App Colors ===
  // Inspired by the app artwork: purple -> pink gradient
  static const Color primary = Color(0xFF7C4DFF); // Purple
  static const Color primaryDark = Color(0xFF5E2ED9);
  static const Color primaryLight = Color(0xFFB39DFF);

  // === Secondary Gradient Colors ===
  static const Color secondary = Color(
    0xFF6CC7FF,
  ); // Accent Blue (kept for UI accents)
  static const Color secondaryLight = Color(0xFFB8E8FF);
  static const Color secondaryDark = Color(0xFF3B9DD8);

  // === Accent Colors ===
  static const Color accent = Color(
    0xFFFF7AB6,
  ); // Soft pink used for highlights
  static const Color accentLight = Color(0xFFFFC7EB);
  static const Color accentDark = Color(0xFFD65A9C);

  // === Background Colors ===
  static const Color scaffoldBackground = Color(
    0xFFF7F5FF,
  ); // Soft lavender background
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkScaffoldBackground = Color(0xFF0B0B0D);
  static const Color darkCardBackground = Color(0xFF141416);

  // === Text Colors ===
  static const Color text = Color(0xFF11121B);
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color subTitle = Color(0xFF7B7C90);
  static const Color hintColor = Color(0xFF9AA0B2);

  // === Button Colors ===
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = secondary;
  static const Color buttonText = Colors.white;
  static const Color buttonTextDark = Colors.black;

  // === Border & Shadows ===
  static const Color border = Color(0xFFECE7F8);
  static const Color borderDark = Color(0xFF2A2A2E);
  static const Color shadow = Color(0x14000000);
  static const Color shadowDark = Color(0x40000000);
  static const Color shadowLight = Color(0x10A1A1A1);

  // === App Gradients ===
  static const Gradient ktGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFFE35FF8)],
  );

  static const Gradient ktGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7C4DFF), Color(0xFFE35FF8)],
  );

  static const Gradient profileGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, primary],
  );

  static const Gradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFFE35FF8)],
  );

  // === Status Colors ===
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color premium = Color(0xFFFFD700);

  // === Action Colors ===
  static const Color like = Color(0xFF1ED760);
  static const Color superLike = Color(0xFF6CC7FF);
  static const Color nope = Color(0xFFFF4CA0);

  // === Social Login Colors ===
  static const Color googleRed = Color(0xFFDB4437);
  static const Color facebookBlue = Color(0xFF4267B2);
  static const Color appleBlack = Color(0xFF000000);

  // === Icons Colors ===
  static const Color iconLightColor = Colors.black;
  static const Color iconDarkColor = Colors.white;

  // === Process Status Colors ===
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFEFA94D);
  static const Color errorColor = Color(0xFFFA3333);
}
