import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../product/presentation/widgets/product_card.dart';
import '../provider/brand_provider.dart';

class BrandProductsScreen extends StatefulWidget {
  final String brandName;

  const BrandProductsScreen({super.key, required this.brandName});

  @override
  State<BrandProductsScreen> createState() => _BrandProductsScreenState();
}

class _BrandProductsScreenState extends State<BrandProductsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final brandProvider = context.read<BrandProvider>();
      await Future.wait([
        brandProvider.getBrandProducts(name: widget.brandName, page: 1),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.brandName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [AppCartCounter(), SizedBox(width: 4)],
      ),
      body: Consumer<BrandProvider>(
        builder: (context, provider, child) {
          return AppPagination(
            controller: _scrollController,
            isLoading: provider.isLoading,
            hasMore: provider.hasMore,
            onLoadMore: () async => await provider.getBrandProducts(
              name: widget.brandName,
              page: provider.page + 1,
            ),
            builder: (context, _) {
              return AppBody(
                controller: _scrollController,
                children: [
                  // ─────────────────────────────────────────
                  // ! Brand Blurb - Coming Soon
                  // ─────────────────────────────────────────

                  // const SizedBox(height: AppConst.spaceXL),

                  // ─────────────────────────────────────────
                  // Filters
                  // ─────────────────────────────────────────
                  const SizedBox(height: AppConst.spaceLG),

                  // ─────────────────────────────────────────
                  // Product Grid
                  // ─────────────────────────────────────────
                  AppGridBuilder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    items: provider.brandProducts,
                    itemBuilder: (context, product, index) {
                      return ProductCard(product: product);
                    },
                  ),

                  const SizedBox(height: AppConst.spaceLG),

                  // Loading Indicator
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
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
