import 'package:flutter/material.dart';

import '../../data/model/product_model.dart';
import 'product_detail_fragrance_card.dart';
import 'product_detail_stock_badge.dart';

class ProductDetailBody extends StatelessWidget {
  final ProductModel product;

  const new({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.brand.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ProductDetailStockBadge(
                stock: product.stock,
                status: product.status,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${product.currency} ${product.price.toStringAsFixed(2)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          if (product.description != null &&
              product.description!.isNotEmpty) ...[
            Text(
              'Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
          ProductDetailFragranceCard(
            fragrance: product.fragrance,
            notes: product.fragranceNotes,
            info: product.productInfo,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
