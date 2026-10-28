import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../data/review_model.dart';
import '../widgets/star_rating.dart';
import '../widgets/write_review_sheet.dart';

/// Every perfume the customer bought, to review or edit the review.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<PurchasedReview>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!AuthPreferences.isAuthenticated) return;
    try {
      final items = await reviewDatasource.mine();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is ApiException
            ? error.message
            : 'Could not reach the shop. Is Laragon running?',
      );
    }
  }

  Future<void> _write(PurchasedReview item) async {
    final changed = await showWriteReviewSheet(
      context,
      productId: item.product.id,
      productName: item.product.name,
      existing: item.review,
    );
    if (changed) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final items = _items;

    Widget body;
    if (!AuthPreferences.isAuthenticated) {
      body = _Message(
        icon: Iconsax.star_1,
        title: 'Sign in to review your perfumes',
        action: AppButton(
          'Sign in',
          width: 160,
          onTap: () => context.go(Routes.login),
        ),
      );
    } else if (items == null && _error != null) {
      body = _Message(
        icon: Iconsax.warning_2,
        title: _error!,
        action: AppButton('Try again', width: 160, onTap: _load),
      );
    } else if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      body = _Message(
        icon: Iconsax.star_1,
        title: 'Nothing to review yet',
        subtitle: 'Perfumes you buy show up here so you can rate them.',
        action: AppButton(
          'Start shopping',
          width: 180,
          onTap: () => context.go(Routes.main),
        ),
      );
    } else {
      final toReview = items.where((item) => item.review == null).length;
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConst.spaceMD),
          children: [
            if (toReview > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConst.spaceMD),
                child: Text(
                  '$toReview perfume${toReview == 1 ? ' is' : 's are'} '
                  'waiting for your review',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final item in items) ...[
              _PurchaseCard(item: item, onWrite: () => _write(item)),
              const SizedBox(height: AppConst.spaceMD),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My reviews', style: textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
      ),
      body: body,
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.item, required this.onWrite});

  final PurchasedReview item;
  final Future<void> Function() onWrite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final product = item.product;
    final review = item.review;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: AppConst.borderRadiusLG,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.productDetail, extra: product),
        child: Padding(
          padding: const EdgeInsets.all(AppConst.spaceMD),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(
                image: product.images.displayImage(product.defaultImageIndex),
                width: 64,
                height: 64,
                borderRadius: AppConst.borderRadiusMD,
              ),
              const SizedBox(width: AppConst.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      product.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (review == null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: onWrite,
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Write a review'),
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          StarRating(rating: review.rating.toDouble()),
                          const SizedBox(width: 6),
                          Text(
                            review.dateLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (review.comment.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          review.comment,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (review != null)
                IconButton(
                  tooltip: 'Edit your review',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onWrite,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConst.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: AppConst.spaceMD),
            Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppConst.spaceSM),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppConst.spaceLG),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
