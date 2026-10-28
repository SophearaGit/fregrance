import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../data/review_model.dart';
import 'star_rating.dart';
import 'write_review_sheet.dart';

/// Ratings and reviews on the product page.
class ProductReviewsSection extends StatefulWidget {
  const ProductReviewsSection({
    super.key,
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  ReviewSummary? _summary;
  List<ReviewModel> _reviews = [];
  int _page = 1;
  bool _loadingMore = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    liveUpdates.addListener(_onDataChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    liveUpdates.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => unawaited(_load());

  /// Reload the first page (and keep as many as were showing).
  Future<void> _load() async {
    try {
      final summary = await reviewDatasource.getForProduct(
        widget.productId,
        limit: 5 * _page,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _reviews = summary.reviews;
        _failed = false;
      });
    } catch (_) {
      if (mounted && _summary == null) setState(() => _failed = true);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = await reviewDatasource.getForProduct(
        widget.productId,
        page: _page + 1,
      );
      if (!mounted) return;
      final seen = {for (final review in _reviews) review.id};
      setState(() {
        _page++;
        _reviews = [
          ..._reviews,
          ...next.reviews.where((review) => !seen.contains(review.id)),
        ];
        _summary = next;
      });
    } catch (_) {
      // Keep what is showing; the button stays for another try.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _write() async {
    final changed = await showWriteReviewSheet(
      context,
      productId: widget.productId,
      productName: widget.productName,
      existing: _summary?.myReview,
    );
    if (changed) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summary = _summary;

    final title = Text(
      'Reviews',
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );

    if (summary == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppConst.spaceSM),
          _failed
              ? TextButton(
                  onPressed: _load,
                  child: const Text('Could not load reviews. Try again'),
                )
              : const Padding(
                  padding: EdgeInsets.all(AppConst.spaceMD),
                  child: Center(child: CircularProgressIndicator()),
                ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: AppConst.spaceMD),
        if (summary.count > 0) _Overview(summary: summary),
        if (summary.count == 0)
          Text(
            'No reviews yet.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: AppConst.spaceMD),
        _WriteAction(summary: summary, onWrite: _write),
        for (final review in _reviews) ...[
          const Divider(height: AppConst.spaceLG * 2),
          _ReviewTile(review: review, onEdit: review.isMine ? _write : null),
        ],
        if (summary.hasMore) ...[
          const SizedBox(height: AppConst.spaceSM),
          Center(
            child: _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppConst.spaceSM),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: _loadMore,
                    child: Text('Show more reviews (${summary.count})'),
                  ),
          ),
        ],
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              summary.average.toStringAsFixed(1),
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            StarRating(rating: summary.average),
            const SizedBox(height: 4),
            Text(
              '${summary.count} review${summary.count == 1 ? '' : 's'}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppConst.spaceLG),
        Expanded(
          child: Column(
            children: [
              for (var stars = 5; stars >= 1; stars--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text('$stars', style: textTheme.bodySmall),
                      ),
                      const Icon(Icons.star_rounded, size: 14, color: starColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppConst.borderRadiusFull,
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: summary.count == 0
                                ? 0
                                : (summary.breakdown[stars] ?? 0) /
                                      summary.count,
                            color: starColor,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${summary.breakdown[stars] ?? 0}',
                          textAlign: TextAlign.end,
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Write a review", "Edit your review", or why the customer can't yet.
class _WriteAction extends StatelessWidget {
  const _WriteAction({required this.summary, required this.onWrite});

  final ReviewSummary summary;
  final Future<void> Function() onWrite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!AuthPreferences.isAuthenticated) {
      return TextButton.icon(
        onPressed: () => context.go(Routes.login),
        icon: const Icon(Icons.login),
        label: const Text('Sign in to write a review'),
      );
    }
    if (summary.myReview != null || summary.canReview) {
      return AppButton(
        summary.myReview != null ? 'Edit your review' : 'Write a review',
        icon: summary.myReview != null
            ? Icons.edit_outlined
            : Icons.rate_review_outlined,
        variant: ButtonVariant.outline,
        height: 44,
        onTap: onWrite,
      );
    }
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'You can review this perfume after you buy it.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, this.onEdit});

  final ReviewModel review;
  final Future<void> Function()? onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initial = Text(
      review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
      style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
    );
    final photo = review.userPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: photo == null || photo.isEmpty
                  ? initial
                  : AppImage(
                      image: photo,
                      variant: ImageVariant.avatar,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, _, _) => Center(child: initial),
                    ),
            ),
            const SizedBox(width: AppConst.spaceSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.isMine
                        ? '${review.userName} (you)'
                        : review.userName,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      StarRating(rating: review.rating.toDouble(), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        review.dateLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                tooltip: 'Edit your review',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: AppConst.spaceSM),
          Text(
            review.comment,
            style: textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ],
    );
  }
}
