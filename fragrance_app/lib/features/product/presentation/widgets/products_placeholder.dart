import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_grid_builder.dart';
import '../provider/product_provider.dart';
import 'product_card.dart';

class ProductsPlaceholder extends StatefulWidget {
  const ProductsPlaceholder({super.key});

  @override
  State<ProductsPlaceholder> createState() => _ProductsPlaceholderState();
}

class _ProductsPlaceholderState extends State<ProductsPlaceholder> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProductProvider>().getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return AppGridBuilder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          items: provider.products,
          itemBuilder: (context, product, index) {
            return ProductCard(product: product);
          },
        );
      },
    );
  }
}
