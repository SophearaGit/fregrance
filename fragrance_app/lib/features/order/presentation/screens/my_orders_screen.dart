import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../data/model/order_model.dart';
import '../provider/order_provider.dart';

/// Every order the customer placed, newest first.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async => context.read<OrderProvider>().loadOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders;

    Widget body;
    if (!AuthPreferences.isAuthenticated) {
      body = _Message(
        icon: Iconsax.user,
        title: 'Sign in to see your orders',
        action: AppButton(
          'Sign in',
          width: 160,
          onTap: () => context.push(Routes.login),
        ),
      );
    } else if (provider.isLoading && orders.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && orders.isEmpty) {
      body = _Message(
        icon: Iconsax.warning_2,
        title: provider.error!,
        action: AppButton(
          'Try again',
          width: 160,
          onTap: provider.loadOrders,
        ),
      );
    } else if (orders.isEmpty) {
      body = _Message(
        icon: Iconsax.bag_2,
        title: 'No orders yet',
        subtitle: 'When you buy something, it shows up here.',
        action: AppButton(
          'Start shopping',
          width: 180,
          onTap: () => context.go(Routes.main),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: provider.loadOrders,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConst.spaceMD),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppConst.spaceMD),
          itemBuilder: (context, index) => _OrderCard(order: orders[index]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My orders', style: textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
      ),
      body: body,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  static String _date(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final (Color fg, Color bg) = switch (order.status) {
      'cancelled' || 'failed' => (
        colorScheme.error,
        colorScheme.error.withValues(alpha: 0.12),
      ),
      'pending' => (
        colorScheme.onSurfaceVariant,
        colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
      ),
      _ => (colorScheme.primary, colorScheme.primary.withValues(alpha: 0.12)),
    };

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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: AppConst.borderRadiusFull,
                  ),
                  child: Text(
                    order.statusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_date(order.createdAt)} · ${order.paymentLabel}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConst.spaceSM),
            Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConst.spaceSM),
            Row(
              children: [
                Text(
                  '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (order.canConfirmReceived) ...[
              const SizedBox(height: AppConst.spaceMD),
              AppButton(
                'I received it',
                height: 42,
                variant: ButtonVariant.outline,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final error = await context
                      .read<OrderProvider>()
                      .markReceived(order.id);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Thanks! Enjoy your scent.'),
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
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
