import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({
    super.key,
    required this.subtotal,
    required this.itemCount,
    required this.onCheckout,
    this.isLoading = false,
    this.note,
  });

  final double subtotal;
  final int itemCount;

  /// Null disables the button.
  final VoidCallback? onCheckout;
  final bool isLoading;

  /// Shown above the button, e.g. why checkout is disabled.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // The backend charges the item total only, so shipping is free.
    final total = subtotal;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConst.spaceMD,
        AppConst.spaceMD,
        AppConst.spaceMD,
        AppConst.spaceLG,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConst.radiusLG),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
              label: 'Subtotal ($itemCount ${itemCount == 1 ? 'item' : 'items'})',
              value: '\$${subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            const _SummaryRow(label: 'Shipping', value: 'Free'),
            const SizedBox(height: AppConst.spaceSM),
            Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
            const SizedBox(height: AppConst.spaceSM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: AppConst.spaceSM),
              Text(
                note!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: AppConst.spaceMD),
            AppButton(
              'Checkout',
              icon: Iconsax.card,
              isLoading: isLoading,
              onTap: onCheckout,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: textTheme.bodyMedium),
      ],
    );
  }
}
