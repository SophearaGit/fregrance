import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/core.dart';
import 'cart_quantity_button.dart';

class CartQuantityPill extends StatelessWidget {
  const CartQuantityPill({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    this.canIncrease = true,
  });

  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  /// False when there is no more stock to add.
  final bool canIncrease;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final canDecrease = quantity > 1;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: AppConst.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CartQuantityButton(
            icon: Iconsax.minus,
            onTap: canDecrease ? onDecrease : null, // locked at 1
            enabled: canDecrease,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CartQuantityButton(
            icon: Iconsax.add,
            onTap: canIncrease ? onIncrease : null,
            enabled: canIncrease,
          ),
        ],
      ),
    );
  }
}
