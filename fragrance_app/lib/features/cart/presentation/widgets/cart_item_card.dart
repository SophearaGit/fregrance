import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_quantity_pill.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasDiscount = item.hasDiscount;
    final warning = !item.isAvailable
        ? 'No longer available. Remove it to check out.'
        : item.exceedsStock
        ? 'Only ${item.stock} left. Lower the quantity to check out.'
        : null;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: AppConst.borderRadiusLG,
      child: Padding(
        padding: const EdgeInsets.all(AppConst.spaceMD),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product photo
            Opacity(
              opacity: item.isAvailable ? 1 : 0.45,
              child: AppImage(
                image: item.imageUrl,
                width: 84,
                height: 84,
                background: true,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                errorBuilder: (context, _, _) => Container(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  child: Icon(
                    Iconsax.shop,
                    size: 28,
                    color: colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppConst.spaceMD),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand + remove
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.brand,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      InkResponse(
                        onTap: onRemove,
                        radius: 20,
                        child: Icon(
                          Iconsax.trash,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Text(
                    item.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  Text(
                    item.size,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppConst.spaceSM),

                  // Price + Quantity
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            if (hasDiscount)
                              Text(
                                _money(item.price),
                                style: textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            Text(
                              _money(item.unitPrice),
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: hasDiscount ? colorScheme.primary : null,
                              ),
                            ),
                            if (hasDiscount)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: AppConst.borderRadiusFull,
                                ),
                                child: Text(
                                  '-${item.discount!.toStringAsFixed(0)}%',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      CartQuantityPill(
                        quantity: item.quantity,
                        onIncrease: onIncrease,
                        onDecrease: onDecrease,
                        canIncrease: item.canIncrease,
                      ),
                    ],
                  ),

                  // Line total when buying more than one
                  if (item.quantity > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity} × ${_money(item.unitPrice)} = '
                      '${_money(item.lineTotal)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  if (warning != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      warning,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (!item.canIncrease && item.isAvailable) ...[
                    const SizedBox(height: 6),
                    Text(
                      'That is all we have (${item.stock} in stock).',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "$115" for whole amounts, "$93.50" otherwise.
  static String _money(double value) => value == value.roundToDouble()
      ? '\$${value.toStringAsFixed(0)}'
      : '\$${value.toStringAsFixed(2)}';
}
