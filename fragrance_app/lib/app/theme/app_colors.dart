import 'package:flutter/material.dart';

abstract final class AppColors {
  // dart format off

  // ===========================================================
  // Brand Palette

  /// Rose Quartz / Muted Amber-Rose
  static const primary   = Color(0xFFC48B9F);

  /// Deep Velvet Plum
  static const secondary = Color(0xFF8C5E72);

  /// Warm Champagne Gold
  static const accent    = Color(0xFFE5C384);
  // ===========================================================


  // ===========================================================
  // Light Theme (Silky Glass & Satin)

  /// Soft ivory with subtle rose tint
  static const lightBackground    = Color(0xFFFAF7F8);

  /// Pure frosted white
  static const lightSurface       = Color(0xFFFFFFFF);

  /// Soft espresso-plum black
  static const lightText          = Color(0xFF1F181C);

  /// Muted cashmere gray
  static const lightSecondaryText = Color(0xFF7A6E75);

  /// Delicate rose-quartz border
  static const lightOutline       = Color(0xFFEBE2E6);
  // ===========================================================


  // ===========================================================
  // Dark Theme (Atmospheric Velvet & Gold)

  /// Deep velvet obsidian
  static const darkBackground     = Color(0xFF120E14);

  /// Rich translucent dark plum panel
  static const darkSurface        = Color(0xFF1E1722);

  /// Warm silk white
  static const darkText           = Color(0xFFF7F2F5);

  /// Soft mauve-tinted gray
  static const darkSecondaryText  = Color(0xFFB5A4AE);

  /// Subtle warm amber-plum outline
  static const darkOutline        = Color(0xFF3B2F39);
  // ===========================================================


  // ===========================================================
  // Semantic

  /// Velvet ruby red
  static const error   = Color(0xFFE05263);

  /// Rich amber gold
  static const warning = Color(0xFFE5A642);

  /// Sage emerald
  static const success = Color(0xFF53AC72);

  /// Elegant plum-mauve
  static const info    = Color(0xFF987284);

  /// Champagne gold
  static const loading = Color(0xFFE5C384);
  // ===========================================================
}
