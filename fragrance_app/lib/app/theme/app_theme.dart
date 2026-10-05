import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  // dart format off

  // ===========================================================
  // Light Theme (Silky Glass & Satin)
  // ===========================================================
  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: AppColors.lightBackground,

    colorScheme: const ColorScheme.light(
      primary     : AppColors.primary,
      onPrimary   : Colors.white,

      secondary   : AppColors.secondary,
      onSecondary : Colors.white,

      tertiary    : AppColors.accent,
      onTertiary  : AppColors.lightText,

      surface               : AppColors.lightBackground,
      surfaceContainerLow   : AppColors.lightBackground,
      surfaceContainer      : AppColors.lightSurface,
      surfaceContainerHigh  : AppColors.lightSurface,

      onSurface             : AppColors.lightText,
      onSurfaceVariant      : AppColors.lightSecondaryText,

      outline               : AppColors.lightOutline,

      error                 : AppColors.error,
      onError               : Colors.white,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.lightText),
    ),

    textTheme: TextTheme(
      headlineLarge   : AppTextStyles.headlineLarge.copyWith(color  : AppColors.lightText),
      headlineMedium  : AppTextStyles.headlineMedium.copyWith(color : AppColors.lightText),
      headlineSmall   : AppTextStyles.headlineSmall.copyWith(color  : AppColors.lightText),

      titleLarge      : AppTextStyles.titleLarge.copyWith(color     : AppColors.lightText),
      titleMedium     : AppTextStyles.titleMedium.copyWith(color    : AppColors.lightText),
      titleSmall      : AppTextStyles.titleSmall.copyWith(color     : AppColors.lightText),

      bodyLarge       : AppTextStyles.bodyLarge.copyWith(color      : AppColors.lightText),
      bodyMedium      : AppTextStyles.bodyMedium.copyWith(color     : AppColors.lightText),
      bodySmall       : AppTextStyles.bodySmall.copyWith(color      : AppColors.lightSecondaryText),

      labelLarge      : AppTextStyles.labelLarge.copyWith(color     : AppColors.lightText),
      labelMedium     : AppTextStyles.labelMedium.copyWith(color    : AppColors.lightSecondaryText),
      labelSmall      : AppTextStyles.labelSmall.copyWith(color     : AppColors.lightSecondaryText),
    ),
  );


  // ===========================================================
  // Dark Theme (Atmospheric Velvet & Gold)
  // ===========================================================
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: AppColors.darkBackground,

    colorScheme: const ColorScheme.dark(
      primary     : AppColors.primary,
      onPrimary   : Colors.white,

      secondary   : AppColors.secondary,
      onSecondary : Colors.white,

      tertiary    : AppColors.accent,
      onTertiary  : AppColors.darkBackground,

      surface               : AppColors.darkBackground,
      surfaceContainerLow   : AppColors.darkBackground,
      surfaceContainer      : AppColors.darkSurface,
      surfaceContainerHigh  : AppColors.darkSurface,

      onSurface         : AppColors.darkText,
      onSurfaceVariant  : AppColors.darkSecondaryText,

      outline           : AppColors.darkOutline,

      error             : AppColors.error,
      onError           : Colors.white,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.darkText),
    ),

    textTheme: TextTheme(
      headlineLarge   : AppTextStyles.headlineLarge.copyWith(color  : AppColors.darkText),
      headlineMedium  : AppTextStyles.headlineMedium.copyWith(color : AppColors.darkText),
      headlineSmall   : AppTextStyles.headlineSmall.copyWith(color  : AppColors.darkText),

      titleLarge      : AppTextStyles.titleLarge.copyWith(color     : AppColors.darkText),
      titleMedium     : AppTextStyles.titleMedium.copyWith(color    : AppColors.darkText),
      titleSmall      : AppTextStyles.titleSmall.copyWith(color     : AppColors.darkText),

      bodyLarge       : AppTextStyles.bodyLarge.copyWith(color      : AppColors.darkText),
      bodyMedium      : AppTextStyles.bodyMedium.copyWith(color     : AppColors.darkText),
      bodySmall       : AppTextStyles.bodySmall.copyWith(color      : AppColors.darkSecondaryText),

      labelLarge      : AppTextStyles.labelLarge.copyWith(color     : AppColors.darkText),
      labelMedium     : AppTextStyles.labelMedium.copyWith(color    : AppColors.darkSecondaryText),
      labelSmall      : AppTextStyles.labelSmall.copyWith(color     : AppColors.darkSecondaryText),
    ),
  );

  // dart format on
}
