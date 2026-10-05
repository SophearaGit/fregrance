import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../product/data/model/product_model.dart';

class HomeBentoCard extends StatelessWidget {
  const HomeBentoCard({
    super.key,
    required this.height,
    required this.product,
    required this.fallbackTitle,
    required this.fallbackSubtitle,
    required this.icon,
    required this.onTap,
    this.imageIndex = 0, // Default active image index from the list
    this.compact = false,
  });

  final double height;
  final ProductModel? product;
  final String fallbackTitle;
  final String fallbackSubtitle;
  final IconData icon;
  final VoidCallback onTap;
  final int imageIndex;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final displayTitle = product?.name ?? fallbackTitle;
    final displaySubtitle = product?.brand ?? fallbackSubtitle;

    // Safely extract the image URL from the product's images list using index
    String? imageUrl;
    if (product?.images != null && product!.images.isNotEmpty) {
      final safeIndex = imageIndex < product!.images.length ? imageIndex : 0;
      imageUrl = product!.images[safeIndex];
    }

    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: AppConst.borderRadiusLG,
        clipBehavior: Clip
            .antiAlias, // Ensures the background image respects rounded corners
        child: InkWell(
          onTap: onTap,
          borderRadius: AppConst.borderRadiusLG,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image using your custom AppImage component
              if (hasImage)
                AppImage(
                  image: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: height,
                ),

              // 2. Dark Gradient Overlay for text readability (only if image exists)
              if (hasImage)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(10),
                        Colors.black.withAlpha(20),
                      ],
                    ),
                  ),
                ),

              // 3. Card Content Layout
              Padding(
                padding: EdgeInsets.all(
                  compact ? AppConst.spaceMD : AppConst.spaceLG,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: compact ? 36 : 44,
                      height: compact ? 36 : 44,
                      decoration: BoxDecoration(
                        color: hasImage
                            ? Colors.white.withAlpha(40)
                            : colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: AppConst.borderRadiusSM,
                      ),
                      child: Icon(
                        icon,
                        size: compact ? 18 : 22,
                        color: hasImage ? Colors.white : colorScheme.primary,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (compact
                                      ? textTheme.titleSmall
                                      : textTheme.titleMedium)
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: hasImage ? Colors.white : null,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displaySubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: hasImage
                                ? Colors.white70
                                : colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
