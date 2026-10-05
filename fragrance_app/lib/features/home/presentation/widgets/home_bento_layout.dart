import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../provider/home_provider.dart';
import 'home_bento_card.dart';

class HomeBentoLayout extends StatelessWidget {
  const HomeBentoLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the featured model from HomeProvider
    final featured = context.watch<HomeProvider>().featured;

    // Extract individual products safely
    final newArrival = featured?.newArrival;
    final topSales = featured?.topSales;
    final trending = featured?.trending;

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large card (New Arrival / Summer Drop)
          Expanded(
            flex: 3,
            child: HomeBentoCard(
              height: 220,
              product: featured?.newArrival,
              fallbackTitle: newArrival?.name ?? 'Summer Drop',
              fallbackSubtitle: newArrival?.brand ?? 'New arrivals',
              icon: Iconsax.shop,
              onTap: () async {
                if (newArrival != null) {
                  await context.push(Routes.productDetail, extra: newArrival);
                }
              },
            ),
          ),
          const SizedBox(width: AppConst.spaceMD),
          // Two stacked small cards
          Expanded(
            flex: 2,
            child: Column(
              children: [
                HomeBentoCard(
                  height: 104,
                  product: featured?.topSales,
                  fallbackTitle: topSales?.name ?? 'Sale',
                  fallbackSubtitle: topSales?.brand ?? 'Top Sales',
                  icon: Iconsax.tag,
                  compact: true,
                  onTap: () async {
                    if (topSales != null) {
                      await context.push(Routes.productDetail, extra: topSales);
                    }
                  },
                ),
                const SizedBox(height: AppConst.spaceMD),
                HomeBentoCard(
                  height: 104,
                  product: featured?.trending,
                  fallbackTitle: trending?.name ?? 'Popular',
                  fallbackSubtitle: trending?.brand ?? 'Trending',
                  icon: Iconsax.chart_2,
                  compact: true,
                  onTap: () async {
                    if (trending != null) {
                      await context.push(Routes.productDetail, extra: trending);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
