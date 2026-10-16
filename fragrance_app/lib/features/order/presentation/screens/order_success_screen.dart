import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';

/// What the success screen shows.
final class OrderSuccessArgs {
  final String? orderId;
  final double amount;
  final String paymentLabel;

  const OrderSuccessArgs({
    required this.orderId,
    required this.amount,
    required this.paymentLabel,
  });
}

/// Shown right after a payment goes through, with clear next steps.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.args});

  final OrderSuccessArgs args;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return PopScope(
      // Back goes to the shop, not to the (now empty) cart.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.main);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppConst.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.tick_circle,
                        size: 56,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConst.spaceLG),
                  Text(
                    'Thank you for your order!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConst.spaceSM),
                  Text(
                    'Your payment went through. We are getting your '
                    'scents ready and you can follow the order in My orders.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppConst.spaceXL),

                  // Receipt
                  Container(
                    padding: const EdgeInsets.all(AppConst.spaceMD),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: AppConst.borderRadiusLG,
                    ),
                    child: Column(
                      children: [
                        if (args.orderId != null)
                          _Row(label: 'Order', value: '#${args.orderId}'),
                        _Row(
                          label: 'Paid',
                          value: '\$${args.amount.toStringAsFixed(2)}',
                        ),
                        _Row(label: 'Payment', value: args.paymentLabel),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConst.spaceXL),
                  AppButton(
                    'View my orders',
                    icon: Iconsax.bag_2,
                    onTap: () => context.pushReplacement(Routes.orders),
                  ),
                  const SizedBox(height: AppConst.spaceMD),
                  AppButton(
                    'Continue shopping',
                    variant: ButtonVariant.outline,
                    onTap: () => context.go(Routes.main),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
