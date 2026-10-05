import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../../shared/shared.dart';
import '../router/routes.dart';
import '../theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Toggle 'true' for on hold
  static const bool _pauseForDev = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    if (_pauseForDev) return;

    if (AppPreferences.hasSeenOnboarding) {
      context.go(Routes.main);
    } else {
      context.go(Routes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF1E293B), // Top lighter slate
                    Color(0xFF131D31), // Mid-dark transition
                    Color(0xFF0B1324), // Darker obsidian navy
                    Color(0xFF070C18), // Deep rich navy
                  ]
                : const [
                    Color(0xFFFFFFFF), // Top pure white
                    Color(0xFFFFEAED), // Soft blush accent
                    Color(0xFFFFD1DC), // Vibrant pastel rose
                    Color(0xFFFFB6C1), // Light pink pop
                  ],
            // Sharp stops make the multi-layer bands clearly visible
            stops: const [0.0, 0.25, 0.5, 0.75],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConst.spaceXL),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Keep column compact and centered
                children: [
                  AppImage(
                    image: AppAssets.splashLogo,
                    type: ImageType.asset,
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppConst.spaceXL),
                  Text(
                    'ESSENCE',
                    style: AppTextStyles.headlineMedium.copyWith(
                      letterSpacing: 8.0,
                      fontWeight: FontWeight.w300,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
