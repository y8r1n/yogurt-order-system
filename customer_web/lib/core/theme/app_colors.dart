import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF004DA0);
  static const Color secondary = Color(0xFF247AE2);
  static const Color white = Color(0xFFFFFFFF);

  // Background
  static const Color background = white;
  static const Color surface = Color(0xFFF7F9FC);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFFAAAAAA);
  static const Color textOnPrimary = white;

  // Border / Divider
  static const Color border = Color(0xFFD9E1EA);
  static const Color divider = Color(0xFFE8EDF3);

  // State
  static const Color disabled = Color(0xFFE1E5EA);
  static const Color soldOut = Color(0xFF8A8A8A);
  static const Color error = Color(0xFFD92D20);
  static const Color required = Color(0xFFD92D20);

  // Selection
  static const Color selectedBackground = Color(0xFFEAF3FF);
  static const Color selectedBorder = primary;

  const AppColors._();
}