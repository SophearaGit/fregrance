import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_grid_builder.dart';
import '../../../product/presentation/widgets/product_card.dart';
import '../provider/home_provider.dart';

class HomeFeedProductList extends StatelessWidget {
  const HomeFeedProductList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final feeds = provider.feeds;

    // Show a loading indicator if it's loading and no items are loaded yet
    if (provider.isLoading && feeds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show empty state if no products found
    if (feeds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No products found for this category.'),
        ),
      );
    }

    return AppGridBuilder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      items: provider.feeds,
      itemBuilder: (context, product, index) {
        return ProductCard(product: product);
      },
    );
  }
}
