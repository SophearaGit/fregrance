import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../address/data/model/address_model.dart';
import '../../../address/presentation/provider/address_provider.dart';
import '../../../order/presentation/provider/order_provider.dart';
import '../../../order/presentation/screens/order_success_screen.dart';
import '../../../profile/presentation/provider/profile_provider.dart';
import '../provider/cart_provider.dart';
import '../widgets/cart_empty.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary.dart';
import 'payway_checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final addresses = context.read<AddressProvider>();
      await context.read<CartProvider>().loadCart();
      if (AuthPreferences.isAuthenticated) await addresses.ensureLoaded();
    });
  }

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (!AuthPreferences.isAuthenticated) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please sign in to check out.')),
      );
      await context.push(Routes.login);
      return;
    }

    // Where should it go? Ask for an address if there is none yet.
    final addresses = context.read<AddressProvider>();
    await addresses.ensureLoaded();
    if (!mounted) return;
    final AddressModel address;
    final existing = addresses.selected;
    if (existing != null) {
      address = existing;
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add where we should deliver your order.')),
      );
      final saved = await context.push<bool>(Routes.addressForm);
      if (!mounted || saved != true) return;
      final added = addresses.selected;
      if (added == null) return;
      address = added;
    }
    final delivery = address.deliveryText;

    final total = cart.subtotal.toStringAsFixed(2);
    final method = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay \$$total with',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deliver to ${address.title}: ${address.oneLine}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_rounded),
              title: const Text('ABA PayWay'),
              subtitle: const Text('Card, ABA Pay or KHQR'),
              onTap: () => Navigator.of(context).pop('payway'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded),
              title: const Text('Wallet'),
              subtitle: const Text('Pay from your shop balance'),
              onTap: () => Navigator.of(context).pop('wallet'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || method == null) return;

    if (method == 'payway') {
      await _payWithPayway(delivery);
    } else {
      await _payWithWallet(total, delivery);
    }
  }

  Future<void> _payWithWallet(String total, String delivery) async {
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Place order?'),
        content: Text('\$$total will be paid from your wallet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Pay now'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await cart.checkout(deliveryDetail: delivery);
    if (!mounted) return;

    if (result.success) {
      _goToSuccess(
        orderId: result.orderId,
        amount: double.tryParse(total) ?? 0,
        paymentLabel: 'Wallet',
      );
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(result.message)));
    if (result.needsSignIn) await context.push(Routes.login);
  }

  Future<void> _payWithPayway(String delivery) async {
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final start = await cart.startPayway(deliveryDetail: delivery);
    if (!mounted) return;
    final checkout = start.checkout;
    if (checkout == null) {
      messenger.showSnackBar(SnackBar(content: Text(start.message)));
      if (start.needsSignIn) await context.push(Routes.login);
      return;
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaywayCheckoutScreen(
          checkout: checkout,
          isPaid: () => cart.isPaywayPaid(checkout.tranId),
        ),
      ),
    );
    if (!mounted) return;

    // Ask the backend (which asks PayWay) whether the money arrived.
    while (mounted) {
      final result = await cart.confirmPayway(checkout.tranId);
      if (!mounted) return;

      if (result.status == 'paid') {
        _goToSuccess(
          orderId: checkout.orderId,
          amount: checkout.amount,
          paymentLabel: 'ABA PayWay',
        );
        return;
      }
      if (result.status == 'cancelled') {
        messenger.showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }

      // Pending or could not check: let the customer try again.
      final again = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment not confirmed yet'),
          content: Text(
            '${result.message}\n\nIf you finished paying, tap Check again. '
            'Your cart is kept until the payment is confirmed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Check again'),
            ),
          ],
        ),
      );
      if (again != true) return;
    }
  }

  /// Payment done: show the "Thank you" screen with what to do next.
  void _goToSuccess({
    required String? orderId,
    required double amount,
    required String paymentLabel,
  }) {
    // The wallet balance and the orders list have changed.
    unawaited(context.read<ProfileProvider>().refreshWallet());
    unawaited(context.read<OrderProvider>().loadOrders());
    context.pushReplacement(
      Routes.orderSuccess,
      extra: OrderSuccessArgs(
        orderId: orderId,
        amount: amount,
        paymentLabel: paymentLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final cart = context.watch<CartProvider>();
    final cartItems = cart.cartItems;
    final hasItems = cartItems.isNotEmpty;
    final isFirstLoad = cart.isLoading && !hasItems && cart.itemCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (hasItems)
            TextButton(
              onPressed: cart.isCheckingOut
                  ? null
                  : () async => context.read<CartProvider>().clearCart(),
              child: Text(
                'Clear',
                style: textTheme.labelLarge?.copyWith(color: colorScheme.error),
              ),
            ),
        ],
      ),
      body: isFirstLoad
          ? const Center(child: CircularProgressIndicator())
          : hasItems
          ? Column(
              children: [
                // ── Items ──
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: cart.loadCart,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppConst.spaceMD,
                        AppConst.spaceMD,
                        AppConst.spaceMD,
                        AppConst.spaceXL,
                      ),
                      itemCount: cartItems.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppConst.spaceMD),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return CartItemCard(
                          key: ValueKey(item.productId),
                          item: item,
                          onIncrease: () async =>
                              cart.increase(item.productId),
                          onDecrease: () async =>
                              cart.decrease(item.productId),
                          onRemove: () async => cart.removeId(item.productId),
                        );
                      },
                    ),
                  ),
                ),

                // ── Where it goes ──
                if (AuthPreferences.isAuthenticated)
                  _DeliverTo(
                    address: context.watch<AddressProvider>().selected,
                    onTap: () async {
                      final addresses = context.read<AddressProvider>();
                      if (addresses.addresses.isEmpty) {
                        await context.push<bool>(Routes.addressForm);
                      } else {
                        await context.push<AddressModel>(
                          Routes.addressesPick(),
                        );
                      }
                      if (mounted) setState(() {});
                    },
                  ),

                // ── Bottom Summary ──
                CartSummary(
                  subtotal: cart.subtotal,
                  itemCount: cart.itemCount,
                  isLoading: cart.isCheckingOut,
                  note: cart.hasProblems
                      ? 'Fix the items marked in red to check out.'
                      : null,
                  onCheckout: cart.hasProblems ? null : _checkout,
                ),
              ],
            )
          : const CartEmpty(),
    );
  }
}

/// "Deliver to Home · #12, St 271..." with a Change button.
class _DeliverTo extends StatelessWidget {
  const _DeliverTo({required this.address, required this.onTap});

  final AddressModel? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final a = address;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConst.spaceMD,
        0,
        AppConst.spaceMD,
        AppConst.spaceSM,
      ),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: AppConst.borderRadiusLG,
        child: InkWell(
          borderRadius: AppConst.borderRadiusLG,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConst.spaceMD,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  a == null
                      ? Icons.add_location_alt_outlined
                      : Icons.location_on_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppConst.spaceMD),
                Expanded(
                  child: a == null
                      ? Text(
                          'Add a delivery address',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deliver to ${a.title}',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              a.oneLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
                Text(
                  a == null ? 'Add' : 'Change',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

