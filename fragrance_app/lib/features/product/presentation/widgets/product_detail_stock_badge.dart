import 'package:flutter/material.dart';

import '../../data/model/product_enum.dart';

class ProductDetailStockBadge extends StatelessWidget {
  final int stock;
  final ProductStatus status;
  const new({super.key, required this.stock, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAvailable = stock > 0 && status == ProductStatus.active;

    final badgeColor = isAvailable
        ? colorScheme.primaryContainer
        : colorScheme.errorContainer;
    final textColor = isAvailable
        ? colorScheme.onPrimaryContainer
        : colorScheme.onErrorContainer;
    final label = isAvailable ? '$stock In Stock' : 'Out of Stock';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
