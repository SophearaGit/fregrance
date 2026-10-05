import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../provider/cart_provider.dart';
import '../widgets/cart_empty.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary.dart';

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
      final cartProvider = context.watch<CartProvider>();
      await Future.wait([cartProvider.loadCart()]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final cartItems = context.watch<CartProvider>().cartItems;

    final hasItems = cartItems.isNotEmpty;
    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (hasItems)
            TextButton(
              onPressed: () async => context.read<CartProvider>().clearCart(),
              child: Text(
                'Clear',
                style: textTheme.labelLarge?.copyWith(color: colorScheme.error),
              ),
            ),
        ],
      ),
      body: hasItems
          ? Column(
              children: [
                // ── Items ──
                Expanded(
                  child: ListView.separated(
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
                        item: item,
                        onIncrease: () {
                          // TODO
                        },
                        onDecrease: () {
                          // TODO
                        },
                        onRemove: () {
                          // TODO
                        },
                      );
                    },
                  ),
                ),

                // ── Bottom Summary ──
                CartSummary(
                  subtotal: subtotal,
                  onCheckout: () {
                    // TODO: checkout
                  },
                ),
              ],
            )
          : const CartEmpty(),
    );
  }
}
