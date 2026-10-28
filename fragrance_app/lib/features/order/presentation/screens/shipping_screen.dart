import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../data/model/order_model.dart';
import '../provider/order_provider.dart';

/// Orders that are paid but not received yet, with where each one is.
/// Updates by itself when the admin changes an order's status.
class ShippingScreen extends StatefulWidget {
  const ShippingScreen({super.key});

  @override
  State<ShippingScreen> createState() => _ShippingScreenState();
}

class _ShippingScreenState extends State<ShippingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async => context.read<OrderProvider>().loadOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<OrderProvider>();
    final active = provider.orders
        .where((order) => _Steps.indexOf(order.status) >= 0 &&
            order.status != 'received')
        .toList();
    final waitingPayment = provider.orders
        .where((order) => order.status == 'pending')
        .length;

    Widget body;
    if (!AuthPreferences.isAuthenticated) {
      body = _Message(
        icon: Iconsax.truck,
        title: 'Sign in to track your parcels',
        action: AppButton(
          'Sign in',
          width: 160,
          onTap: () => context.go(Routes.login),
        ),
      );
    } else if (provider.isLoading && provider.orders.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && provider.orders.isEmpty) {
      body = _Message(
        icon: Iconsax.warning_2,
        title: provider.error!,
        action: AppButton('Try again', width: 160, onTap: provider.loadOrders),
      );
    } else if (active.isEmpty) {
      body = _Message(
        icon: Iconsax.truck,
        title: 'Nothing on the way',
        subtitle: waitingPayment > 0
            ? '$waitingPayment order${waitingPayment == 1 ? ' is' : 's are'} '
                  'waiting for payment. See them in My orders.'
            : 'Paid orders show up here until they reach you.',
        action: AppButton(
          'My orders',
          width: 180,
          variant: ButtonVariant.outline,
          onTap: () => context.push(Routes.orders),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: provider.loadOrders,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConst.spaceMD),
          itemCount: active.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppConst.spaceMD),
          itemBuilder: (context, index) => _ShipmentCard(order: active[index]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Shipping', style: textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
      ),
      body: body,
    );
  }
}

/// The journey of a parcel, in order.
abstract final class _Steps {
  static const statuses = [
    'paid',
    'processing',
    'shipping',
    'delivered',
    'received',
  ];
  static const labels = [
    'Paid',
    'Preparing',
    'On the way',
    'Delivered',
    'Received',
  ];
  static const hints = [
    'We got your payment and will start packing soon.',
    'Your perfume is being packed with care.',
    'Your parcel is on its way to you.',
    'The courier says it was delivered. Got it? Let us know below.',
    'Enjoy your scent!',
  ];
  static const icons = [
    Icons.payments_outlined,
    Icons.inventory_2_outlined,
    Icons.local_shipping_outlined,
    Icons.home_outlined,
    Icons.check_circle_outline,
  ];

  static int indexOf(String status) => statuses.indexOf(status);
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final current = _Steps.indexOf(order.status);
    final summary = order.items
        .map((item) => '${item.quantity} × ${item.name}')
        .join(', ');

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: AppConst.borderRadiusLG,
      child: Padding(
        padding: const EdgeInsets.all(AppConst.spaceMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConst.spaceMD),
            _StepBar(current: current),
            const SizedBox(height: AppConst.spaceMD),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConst.spaceSM),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: AppConst.borderRadiusMD,
              ),
              child: Row(
                children: [
                  Icon(
                    _Steps.icons[current],
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppConst.spaceSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _Steps.labels[current],
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(_Steps.hints[current], style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if ((order.deliveryDetail ?? '').isNotEmpty) ...[
              const SizedBox(height: AppConst.spaceMD),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.deliveryDetail!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (order.canConfirmReceived) ...[
              const SizedBox(height: AppConst.spaceMD),
              AppButton(
                'I received it',
                height: 42,
                icon: Icons.check,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final error = await context
                      .read<OrderProvider>()
                      .markReceived(order.id);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        error ??
                            'Thanks! You can now review it from More → Reviews.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Five dots joined by lines; done steps filled, the current one ringed.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final done = colorScheme.primary;
    final todo = colorScheme.outlineVariant;
    const count = 5;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= current ? done : colorScheme.surface,
                  border: Border.all(
                    color: i <= current ? done : todo,
                    width: 2,
                  ),
                  boxShadow: i == current
                      ? [
                          BoxShadow(
                            color: done.withValues(alpha: 0.3),
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: i < current
                    ? Icon(Icons.check, size: 13, color: colorScheme.onPrimary)
                    : null,
              ),
              if (i < count - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i < current ? done : todo,
                      borderRadius: AppConst.borderRadiusFull,
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: Text(
                  _Steps.labels[i],
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == count - 1
                      ? TextAlign.end
                      : TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: i <= current ? done : colorScheme.onSurfaceVariant,
                    fontWeight: i == current ? FontWeight.w700 : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConst.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: AppConst.spaceMD),
            Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppConst.spaceSM),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppConst.spaceLG),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
