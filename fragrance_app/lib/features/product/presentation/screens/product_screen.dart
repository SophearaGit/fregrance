import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/shared.dart';
import '../../data/model/product_model.dart';
import '../provider/product_provider.dart';
import '../widgets/product_card.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  // 1. Create the scroll controller for the page body
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = context.read<ProductProvider>();
      await Future.wait([homeProvider.getProducts()]);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Collections', style: textTheme.titleLarge)),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          // 2. Wrap everything in AppPagination so it listens to the body's scroll position
          return AppPagination(
            isLoading: provider.isLoading,
            hasMore: provider.hasMore,
            controller: _scrollController, // Listens to page scrolling
            onLoadMore: () => provider.getProducts(),
            builder: (context, _) {
              return AppBody(
                controller: _scrollController, // Hooked up to AppBody
                children: [
                  AppGridBuilder<ProductModel>(
                    items: provider.products,
                    shrinkWrap: true, // Safe for nested lists
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, product, index) {
                      return ProductCard(product: product);
                    },
                  ),

                  // 3. Full-width loading indicator at the bottom (not trapped in a grid cell)
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
