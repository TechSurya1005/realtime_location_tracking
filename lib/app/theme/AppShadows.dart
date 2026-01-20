import 'package:flutter/material.dart';

class AppShadows {
  // === Extra Small Shadows ===
  static final xs = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static final xsTop = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, -1),
      spreadRadius: 0,
    ),
  ];

  // === Small Shadows ===
  static final sm = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static final smTop = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, -2),
      spreadRadius: 0,
    ),
  ];

  // === Medium Shadows ===
  static final md = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static final mdTop = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, -4),
      spreadRadius: 0,
    ),
  ];

  // === Large Shadows ===
  static final lg = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static final lgTop = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, -6),
      spreadRadius: 0,
    ),
  ];

  // === Extra Large Shadows ===
  static final xl = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.18),
      blurRadius: 16,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static final xlTop = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.18),
      blurRadius: 16,
      offset: const Offset(0, -8),
      spreadRadius: 0,
    ),
  ];

  // === 2X Large Shadows ===
  static final xxl = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.20),
      blurRadius: 20,
      offset: const Offset(0, 10),
      spreadRadius: 0,
    ),
  ];

  static final xxlTop = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.20),
      blurRadius: 20,
      offset: const Offset(0, -10),
      spreadRadius: 0,
    ),
  ];

  // === 3X Large Shadows ===
  static final xxxl = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  // === Special Purpose Shadows ===

  // Card Shadows
  static final card = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static final cardHover = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Button Shadows
  static final button = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.12),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static final buttonPressed = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.08),
      blurRadius: 2,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  // App Bar Shadow
  static final appBar = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // Floating Action Button
  static final fab = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.20),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static final fabPressed = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.15),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // Dialog Shadows
  static final dialog = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  // Bottom Sheet Shadow
  static final bottomSheet = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.20),
      blurRadius: 16,
      offset: const Offset(0, -4),
      spreadRadius: 0,
    ),
  ];

  // Navigation Bar Shadow
  static final navBar = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.10),
      blurRadius: 8,
      offset: const Offset(0, -2),
      spreadRadius: 0,
    ),
  ];

  // Profile Card Shadow (for dating app)
  static final profileCard = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.20),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // Action Button Shadow (Like/Nope buttons)
  static final actionButton = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  // Premium Badge Shadow
  static final premiumBadge = [
    BoxShadow(
      color: Colors.amber. withValues(alpha: 0.4),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // === Custom Shadow Builder ===
  static List<BoxShadow> custom({
    Color color = Colors.black,
    double opacity = 0.1,
    double blurRadius = 8,
    Offset offset = Offset.zero,
    double spreadRadius = 0,
  }) {
    return [
      BoxShadow(
        color: color. withValues(alpha: opacity),
        blurRadius: blurRadius,
        offset: offset,
        spreadRadius: spreadRadius,
      ),
    ];
  }

  // === Responsive Shadow ===
  static List<BoxShadow> responsive(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1024) return lg; // Desktop
    if (width > 600) return md;  // Tablet
    return sm; // Mobile
  }

  // === Shadow for Dark Theme ===
  static List<BoxShadow> darkThemeShadow = [
    BoxShadow(
      color: Colors.black. withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // === Shadow for Light Theme ===
  static List<BoxShadow> lightThemeShadow = [
    BoxShadow(
      color: Colors.grey. withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
}