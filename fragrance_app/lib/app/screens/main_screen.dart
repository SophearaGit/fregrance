import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const new({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            // iOS Style Multi-Layer Ambient Shadow
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : theme.colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onTap: _onDestinationSelected,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: isDark ? 0.65 : 0.75,
                ),
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.colorScheme.onSurface.withAlpha(150),
                selectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Iconsax.home_2_copy),
                    activeIcon: Icon(Iconsax.home_2),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Iconsax.tag_copy),
                    activeIcon: Icon(Iconsax.tag),
                    label: 'Brand',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Iconsax.search_favorite_1_copy),
                    activeIcon: Icon(Iconsax.search_favorite_1),
                    label: 'Discovery',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Iconsax.more_copy),
                    activeIcon: Icon(Iconsax.more),
                    label: 'More',
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
