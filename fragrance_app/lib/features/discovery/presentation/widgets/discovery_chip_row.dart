import 'package:flutter/material.dart';

import '../../../../core/core.dart';

class DiscoveryChipRow<T> extends StatelessWidget {
  final List<T> items;
  final Future<void> Function(T item) onSelected;
  final String Function(T item) labelBuilder;
  final bool Function(T item)? isSelectedBuilder;

  const DiscoveryChipRow({
    super.key,
    required this.items,
    required this.onSelected,
    required this.labelBuilder,
    this.isSelectedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppConst.spaceSM),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = isSelectedBuilder?.call(item) ?? false;

          return ActionChip(
            label: Text(labelBuilder(item)),
            onPressed: () => onSelected(item),
            backgroundColor: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainer,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: AppConst.borderRadiusFull,
            ),
            labelStyle: textTheme.labelMedium?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}
