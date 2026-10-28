import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../data/review_model.dart';
import 'star_rating.dart';

const _ratingWords = ['', 'Not for me', 'Okay', 'Good', 'Very good', 'Love it'];

/// Bottom sheet to write, edit or delete a review.
/// Returns true when something was saved or deleted.
Future<bool> showWriteReviewSheet(
  BuildContext context, {
  required String productId,
  required String productName,
  ReviewModel? existing,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _WriteReviewSheet(
      productId: productId,
      productName: productName,
      existing: existing,
    ),
  );
  return changed ?? false;
}

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({
    required this.productId,
    required this.productName,
    this.existing,
  });

  final String productId;
  final String productName;
  final ReviewModel? existing;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late int _rating = widget.existing?.rating ?? 0;
  late final TextEditingController _comment = TextEditingController(
    text: widget.existing?.comment ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      setState(() => _error = 'Tap the stars to choose a rating.');
      return;
    }
    await _run(
      () => reviewDatasource.save(
        widget.productId,
        rating: _rating,
        comment: _comment.text.trim(),
      ),
      done: 'Thanks for your review!',
    );
  }

  Future<void> _delete() async {
    final review = widget.existing;
    if (review == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _run(() => reviewDatasource.delete(review.id), done: 'Review deleted');
  }

  Future<void> _run(
    Future<Object?> Function() action, {
    required String done,
  }) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is ApiException
            ? error.message
            : 'Could not reach the shop. Is Laragon running?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConst.spaceLG,
        0,
        AppConst.spaceLG,
        MediaQuery.viewInsetsOf(context).bottom + AppConst.spaceLG,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit your review' : 'Write a review',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.productName,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConst.spaceMD),
            StarPicker(
              value: _rating,
              onChanged: (value) => setState(() {
                _rating = value;
                _error = null;
              }),
            ),
            Text(
              _ratingWords[_rating],
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(color: starColor),
            ),
            const SizedBox(height: AppConst.spaceMD),
            TextField(
              controller: _comment,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'How does it smell? How long does it last? (optional)',
                border: OutlineInputBorder(
                  borderRadius: AppConst.borderRadiusMD,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConst.spaceSM),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: AppConst.spaceMD),
            AppButton(
              isEdit ? 'Save changes' : 'Post review',
              isLoading: _saving,
              onTap: _saving ? null : _save,
            ),
            if (isEdit) ...[
              const SizedBox(height: AppConst.spaceSM),
              TextButton(
                onPressed: _saving ? null : _delete,
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                child: const Text('Delete my review'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
