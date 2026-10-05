import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../provider/discovery_provider.dart';
import '../widgets/discovery_chip_row.dart';
import '../widgets/discovery_note.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final discovery = context.read<DiscoveryProvider>();
      await Future.wait([
        discovery.getMoods(),
        discovery.getNotes(),
        discovery.getOccasions(),
        discovery.getScentFamilies(),
      ]);
      await discovery.getDiscoveryProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiscoveryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery'),
        actions: [
          if (provider.selectedMood != null ||
              provider.selectedNote != null ||
              provider.selectedOccasion != null ||
              provider.selectedScentFamily != null)
            TextButton(
              onPressed: provider.clearFilters,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: AppBody(
        children: [
          // Search
          _DiscoverySearchBar(
            controller: _searchController,
            onChanged: (value) {
              // TODO: implement search (debounce + call repository)
            },
          ),

          const SizedBox(height: AppConst.spaceXL),

          // Mood
          const _SectionHeader(title: 'By Mood'),
          const SizedBox(height: AppConst.spaceMD),
          DiscoveryChipRow<String>(
            items: provider.moods,
            labelBuilder: (item) => item,
            isSelectedBuilder: (mood) => provider.selectedMood == mood,
            onSelected: (mood) async {
              final uri = Uri(
                path: Routes.discoveryProducts,
                queryParameters: {'mood': mood, 'title': mood},
              );
              await context.push(uri.toString());
            },
          ),

          const SizedBox(height: AppConst.spaceXL),

          // Notes – use the dedicated widget
          const _SectionHeader(title: 'By Notes'),
          const SizedBox(height: AppConst.spaceMD),
          const DiscoveryNote(),

          const SizedBox(height: AppConst.spaceXL),

          // Occasion
          const _SectionHeader(title: 'By Occasion'),
          const SizedBox(height: AppConst.spaceMD),
          DiscoveryChipRow<String>(
            items: provider.occasions,
            labelBuilder: (item) => item,
            isSelectedBuilder: (occasions) =>
                provider.selectedOccasion == occasions,
            onSelected: (occasion) async {
              await context.push(
                Uri(
                  path: '/discovery/products',
                  queryParameters: {'occasion': occasion, 'title': occasion},
                ).toString(),
              );
            },
          ),

          const SizedBox(height: AppConst.spaceXL),

          // Scent Families
          const _SectionHeader(title: 'Scent Families'),
          const SizedBox(height: AppConst.spaceMD),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.scentFamilies.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppConst.spaceMD),
              itemBuilder: (context, index) {
                final family = provider.scentFamilies[index];
                // Map icon yourself or keep a simple map
                final icon = _familyIcon(family);
                final isSelected = provider.selectedScentFamily == family;

                return _FamilyCard(
                  title: family,
                  icon: icon,
                  isSelected: isSelected,
                  onTap: () => provider.selectFamily(family),
                );
              },
            ),
          ),

          const SizedBox(height: AppConst.spaceXL),

          // Results / Trending / New Arrivals
          // For now just show filtered products
          _SectionHeader(
            title: 'Results',
            actionLabel: provider.hasMore ? 'Load more' : null,
            onAction: provider.hasMore
                ? () => provider.getDiscoveryProducts(loadMore: true)
                : null,
          ),
          const SizedBox(height: AppConst.spaceMD),

          if (provider.isLoadingProducts && provider.discoveryProducts.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (provider.discoveryProducts.isEmpty)
            const Text('No products found')
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.discoveryProducts.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppConst.spaceMD),
                itemBuilder: (context, index) {
                  final product = provider.discoveryProducts[index];
                  return _ProductMiniCard(
                    name: product.name,
                    brand: product.brand,
                    onTap: () async {
                      await context.push(Routes.productDetail, extra: product);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  IconData _familyIcon(String family) {
    return switch (family.toLowerCase()) {
      'woody' => Iconsax.tree,
      'floral' => Iconsax.emoji_happy,
      'citrus' => Iconsax.sun_1,
      'oriental' => Iconsax.moon,
      'fresh' => Iconsax.cloud,
      _ => Iconsax.shop,
    };
  }
}

// ===========================================================
// Search Bar
// ===========================================================
class _DiscoverySearchBar extends StatelessWidget {
  const _DiscoverySearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search scents, notes, houses...',
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
    );
  }
}

// ===========================================================
// Section Header
// ===========================================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: textTheme.titleMedium),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
            ),
          ),
      ],
    );
  }
}

// ===========================================================
// Family Card
// ===========================================================
class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colorScheme.surfaceContainer,
      borderRadius: AppConst.borderRadiusLG,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppConst.borderRadiusLG,
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(AppConst.spaceMD),
          decoration: BoxDecoration(
            borderRadius: AppConst.borderRadiusLG,
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppConst.borderRadiusSM,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                ),
              ),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// Mini Product Card (for horizontal lists)
// ===========================================================
class _ProductMiniCard extends StatelessWidget {
  const _ProductMiniCard({
    required this.name,
    required this.brand,
    required this.onTap,
  });

  final String name;
  final String brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: AppConst.borderRadiusLG,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppConst.borderRadiusLG,
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConst.radiusLG),
                  ),
                ),
                child: Icon(
                  Iconsax.shop,
                  size: 32,
                  color: colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppConst.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
