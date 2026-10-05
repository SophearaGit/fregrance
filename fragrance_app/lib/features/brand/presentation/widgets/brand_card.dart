import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../data/model/brand_model.dart';

class BrandCard extends StatelessWidget {
  final BrandModel brand;
  final VoidCallback onTap;

  const BrandCard({super.key, required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: AppConst.borderRadiusLG,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppConst.borderRadiusLG,
        child: Padding(
          padding: const EdgeInsets.all(AppConst.spaceMD),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Monogram
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: AppConst.borderRadiusMD,
                ),
                child: Center(child: AppImage(image: brand.image)),
              ),

              const SizedBox(height: AppConst.spaceMD),

              // Brand name
              Text(
                brand.brand,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
