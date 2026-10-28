import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../product/data/model/product_model.dart';
import '../provider/favorite_provider.dart';

/// Heart that saves or un-saves a product.
///
/// [compact] draws a small round badge for use on top of product photos.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key, required this.product, this.compact = false});

  final ProductModel product;
  final bool compact;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<FavoriteProvider>().ensureIds());
  }

  Future<void> _toggle() async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<FavoriteProvider>();
    final wasFavorite = provider.isFavorite(widget.product.id);
    final error = await provider.toggle(widget.product);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            error ??
                (wasFavorite
                    ? 'Removed from favorites'
                    : 'Saved to favorites'),
          ),
          action: error != null && error.startsWith('Sign in')
              ? SnackBarAction(
                  label: 'Sign in',
                  onPressed: () => context.go(Routes.login),
                )
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFavorite = context.select<FavoriteProvider, bool>(
      (provider) => provider.isFavorite(widget.product.id),
    );
    final icon = Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      color: isFavorite ? Colors.redAccent : null,
      size: widget.compact ? 18 : null,
    );

    if (!widget.compact) {
      return IconButton(
        tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
        icon: icon,
        onPressed: _toggle,
      );
    }

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _toggle,
        child: Padding(padding: const EdgeInsets.all(6), child: icon),
      ),
    );
  }
}
