import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../provider/home_provider.dart';
import '../widgets/home_bento_layout.dart';
import '../widgets/home_feed_product_list.dart';
import '../widgets/home_feed_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = context.read<HomeProvider>();
      await Future.wait([
        homeProvider.getFeatured(),
        homeProvider.getFeed(tab: homeProvider.currentTab),
      ]);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text('Scent Seeker', style: textTheme.titleLarge),
          ],
        ),
        actions: const [AppCartCounter(), SizedBox(width: 4)],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final homeProvider = context.read<HomeProvider>();
          await Future.wait([
            homeProvider.getFeatured(),
            homeProvider.getFeed(tab: homeProvider.currentTab),
          ]);
        },
        child: AppBody(
          children: [
            // ─────────────────────────────────────────
            // Search
            // ─────────────────────────────────────────
            _SearchBar(
              controller: _searchController,
              onChanged: (value) {
                // TODO: filter products
              },
              onFilterTap: () {
                // TODO: open filter bottom sheet
              },
            ),
            const SizedBox(height: AppConst.spaceXL),
            // ─────────────────────────────────────────
            // Bento / Featured Section
            // ─────────────────────────────────────────
            Text('Featured', style: textTheme.titleMedium),
            const SizedBox(height: AppConst.spaceLG),
            const HomeBentoLayout(), // Bento layout
            // ─────────────────────────────────────────
            // Feed
            // ─────────────────────────────────────────
            const SizedBox(height: AppConst.spaceLG),
            const HomeFeedSelector(),
            const SizedBox(height: AppConst.spaceLG),
            // ─────────────────────────────────────────
            // Products Section
            // ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Explore', style: textTheme.titleMedium),
                TextButton(
                  onPressed: () async => await context.push(Routes.product),
                  child: Text(
                    'See all',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConst.spaceMD),

            // ─── Provider section (left for you) ───
            const HomeFeedProductList(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// Search Bar
// ===========================================================
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(
                Iconsax.search_normal_1,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConst.spaceMD,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: AppConst.borderRadiusMD,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppConst.borderRadiusMD,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppConst.borderRadiusMD,
                borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConst.spaceSM),
        Material(
          color: colorScheme.surfaceContainer,
          borderRadius: AppConst.borderRadiusMD,
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: AppConst.borderRadiusMD,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                Iconsax.setting_4,
                size: 22,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
