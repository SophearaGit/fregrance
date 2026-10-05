import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/shared.dart';
import '../../../cart/presentation/provider/cart_provider.dart';
import '../../data/model/product_enum.dart';
import '../../data/model/product_model.dart';
import '../widgets/product_detail_body.dart';
import '../widgets/product_detail_carousel.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

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
                onPressed: isAvailable
                    ? () async =>
                          await context.read<CartProvider>().addId(product.id)
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  isAvailable ? 'Add to Cart' : 'Unavailable',
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
