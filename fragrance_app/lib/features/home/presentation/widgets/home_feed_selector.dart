import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../provider/home_provider.dart';

class HomeFeedSelector extends StatelessWidget {
  const HomeFeedSelector({super.key});

  static final List<String> _categories = [
    'All',
    'New',
    'Popular',
    'Sale',
    'Men',
    'Women',
    'Unisex',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final homeProvider = context.watch<HomeProvider>();
    final selectedTab = homeProvider.currentTab;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppConst.spaceSM),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == selectedTab;

          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) async => homeProvider.getFeed(tab: category),
            showCheckmark: false,
            selectedColor: colorScheme.primary,
            labelStyle: textTheme.labelMedium?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            backgroundColor: colorScheme.surfaceContainer,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: AppConst.borderRadiusFull,
            ),
          );
        },
      ),
    );
  }
}
