import 'package:flutter/material.dart';

abstract final class AppConst {
  // dart format off

  // ===========================================================
  // Border Radius (Double values for BorderRadius.circular)

  /// ```dart
  /// radiusXS = 4.0;
  /// ```
  static const radiusXS   = 4.0;

  /// ```dart
  /// radiusSM = 8.0;
  /// ```
  static const radiusSM   = 8.0;

  /// ```dart
  /// radiusMD = 12.0;
  /// ```
  static const radiusMD   = 12.0;

  /// ```dart
  /// radiusLG = 16.0;
  /// ```
  static const radiusLG   = 16.0;

  /// ```dart
  /// radiusXL = 24.0;
  /// ```
  static const radiusXL   = 24.0;

  /// ```dart
  /// radiusFull = 999.0;
  /// ```
  static const radiusFull = 999.0;
  // ===========================================================


  // ===========================================================
  // Corner Radius Objects (Ready to use directly in BoxDecoration / ClipRRect)

  /// ```dart
  /// BorderRadius.all(Radius.circular(4.0));
  /// ```
  static const borderRadiusXS   = BorderRadius.all(Radius.circular(radiusXS));

  /// ```dart
  /// BorderRadius.all(Radius.circular(8.0));
  /// ```
  static const borderRadiusSM   = BorderRadius.all(Radius.circular(radiusSM));

  /// ```dart
  /// BorderRadius.all(Radius.circular(12.0));
  /// ```
  static const borderRadiusMD   = BorderRadius.all(Radius.circular(radiusMD));

  /// ```dart
  /// BorderRadius.all(Radius.circular(16.0));
  /// ```
  static const borderRadiusLG   = BorderRadius.all(Radius.circular(radiusLG));

  /// ```dart
  /// BorderRadius.all(Radius.circular(24.0));
  /// ```
  static const borderRadiusXL   = BorderRadius.all(Radius.circular(radiusXL));

  /// ```dart
  /// BorderRadius.all(Radius.circular(999.0));
  /// ```
  static const borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));
  // ===========================================================


  // ===========================================================
  // Spacing & Padding

  /// ```dart
  /// spaceXS = 2.0;
  /// ```
  static const spaceXS = 2.0;

  /// ```dart
  /// spaceSM = 6.0;
  /// ```
  static const spaceSM = 6.0;

  /// ```dart
  /// spaceMD = 12.0;
  /// ```
  static const spaceMD = 12.0;

  /// ```dart
  /// spaceLG = 26.0;
  /// ```
  static const spaceLG = 16.0;

  /// ```dart
  /// spaceXL = 24.0;
  /// ```
  static const spaceXL = 24.0;
  // ===========================================================


  // ===========================================================
  // Edge Insets Shortcuts

  /// ```dart
  /// EdgeInsets.all(6.0)
  /// ```
  static const paddingScreen = EdgeInsets.all(6);

  /// ```dart
  /// EdgeInsets.all(4.0);
  /// ```
  static const paddingCard   = EdgeInsets.all(spaceXS);
  // ===========================================================


  // ===========================================================
  // Animation Durations

  /// ```dart
  /// Duration(milliseconds: 150);
  /// ```
  static const durationFast   = Duration(milliseconds: 150);

  /// ```dart
  /// Duration(milliseconds: 250);
  /// ```
  static const durationNormal = Duration(milliseconds: 250);

  /// ```dart
  /// Duration(milliseconds: 400);
  /// ```
  static const durationSlow   = Duration(milliseconds: 400);
  // ===========================================================
}

// dart format off
