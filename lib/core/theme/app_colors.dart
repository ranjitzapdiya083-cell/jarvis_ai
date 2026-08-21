import 'package:flutter/material.dart';

/// JARVIS AI color tokens.
/// Dedicated dark & light token sets — light mode is NOT a naive inversion
/// of dark mode, per design spec section 40.
class AppColors {
  AppColors._();

  // Brand accents (shared across themes)
  static const Color electricBlue = Color(0xFF3D8BFF);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ---- Dark theme tokens ----
  static const Color darkBg = Color(0xFF0A0B12);
  static const Color darkSurface = Color(0xFF13141F);
  static const Color darkSurfaceElevated = Color(0xFF1B1D2B);
  static const Color darkBorder = Color(0xFF262838);
  static const Color darkTextPrimary = Color(0xFFF5F6FA);
  static const Color darkTextSecondary = Color(0xFF9497AB);
  static const Color darkTextTertiary = Color(0xFF6B6E82);

  // ---- Light theme tokens ----
  static const Color lightBg = Color(0xFFF7F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4E6EF);
  static const Color lightTextPrimary = Color(0xFF14151F);
  static const Color lightTextSecondary = Color(0xFF5B5D70);
  static const Color lightTextTertiary = Color(0xFF8B8DA0);

  static const LinearGradient orbGradient = LinearGradient(
    colors: [electricBlue, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
