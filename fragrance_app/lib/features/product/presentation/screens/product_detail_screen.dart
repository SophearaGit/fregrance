import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../cart/presentation/provider/cart_provider.dart';
import '../../data/model/product_enum.dart';
import '../../data/model/product_model.dart';
import '../widgets/product_detail_body.dart';
import '../widgets/product_detail_carousel.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  /// Starts as the product that was tapped, then follows admin-site edits.
  late ProductModel product = widget.product;

  @override
  void initState() {
    super.initState();
    liveUpdates.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    liveUpdates.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => unawaited(_reload());

  Future<void> _reload() async {
    try {
      final fresh = await productRepository.getOneProductById(product.id);
      if (mounted) setState(() => product = fresh);
    } catch (_) {
      // Deleted or hidden in the admin site: keep showing what we have.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          AppCartCounter(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductDetailCarousel(
              // A new key rebuilds the carousel when the photos change.
              key: ValueKey(product.images.join('|')),
              images: product.images,
              defaultImageIndex: product.defaultImageIndex ?? 0,
            ),
            ProductDetailBody(product: product),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAvailable =
        product.stock > 0 && product.status == ProductStatus.active;
    final inCart = context.watch<CartProvider>().quantityOf(product.id);
    final canAdd = isAvailable && inCart < product.stock;
    final label = !isAvailable
        ? 'Unavailable'
        : !canAdd
        ? 'All ${product.stock} are in your cart'
        : inCart > 0
        ? 'Add another ($inCart in cart)'
        : 'Add to Cart';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: canAdd
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final added = await context
                            .read<CartProvider>()
                            .addId(product.id, stock: product.stock);
                        if (!added) return;
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 2),
                              content: Text('Added to cart'),
                            ),
                          );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
