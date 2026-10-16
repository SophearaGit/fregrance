import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../cart/presentation/provider/cart_provider.dart';
import '../../data/model/product_model.dart';

final class ProductCard extends StatelessWidget {
  final ProductModel product;

  const new({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: AppConst.borderRadiusSM,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.productDetail, extra: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIX 2: Expanded image lets it fill available card space without overflowing
            Expanded(
              child: AppImage(
                image: product.images.displayImage(product.defaultImageIndex),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConst.radiusSM),
                ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(AppConst.spaceSM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge,
                  ),
                  Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withAlpha(130),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${product.price} ${product.currency}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final added = await context
                                .read<CartProvider>()
                                .addId(product.id, stock: product.stock);
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 2),
                                  content: Text(
                                    added
                                        ? '${product.name} added to cart'
                                        : 'No more ${product.name} in stock',
                                  ),
                                ),
                              );
                          },
                          icon: Icon(Iconsax.add_square_copy, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
