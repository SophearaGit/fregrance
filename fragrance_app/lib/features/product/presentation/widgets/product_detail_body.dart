import 'package:flutter/material.dart';

import '../../../review/presentation/widgets/product_reviews_section.dart';
import '../../../review/presentation/widgets/star_rating.dart';
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
          if (product.reviewCount > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                StarRating(rating: product.rating ?? 0),
                const SizedBox(width: 6),
                Text(
                  '${(product.rating ?? 0).toStringAsFixed(1)} '
                  '(${product.reviewCount} review${product.reviewCount == 1 ? '' : 's'})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
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
          const SizedBox(height: 32),
          ProductReviewsSection(
            key: ValueKey(product.id),
            productId: product.id,
            productName: product.name,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
