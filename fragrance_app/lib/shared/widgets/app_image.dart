import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/core.dart';

enum ImageVariant {
  avatar, // Circle
  square, // Sharp Corner
  rounded, // Smooth Corner
}

enum ImageType { asset, network, file }

/// A production-ready image component optimized for API integration.
class AppImage extends StatelessWidget {
  final String? image;
  final ImageVariant variant;
  final ImageType type;
  final double? width;
  final double? height;
  final double? padding;
  final BorderRadius? borderRadius;
  final BoxFit? fit;
  final Alignment? alignment;
  final bool background;
  final Color? backgroundColor;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, String)? placeholder;

  const AppImage({
    super.key,
    required this.image,
    this.variant = ImageVariant.rounded,
    this.type = ImageType.network,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.alignment,
    this.fit = BoxFit.cover,
    this.background = false,
    this.backgroundColor,
    this.errorBuilder,
    this.placeholder,
  });

  BorderRadius? get _borderRadius {
    // Uses BoxShape.circle instead
    if (variant == ImageVariant.avatar) return null;

    switch (variant) {
      case ImageVariant.rounded:
        return borderRadius ?? AppConst.borderRadiusMD;
      case ImageVariant.square:
        return borderRadius ?? BorderRadius.zero;
      case ImageVariant.avatar:
        return null;
    }
  }

  /// Shown when there is no photo or it fails to load: a soft perfume-bottle
  /// picture, with "No image" underneath when there is room for it.
  Widget _buildFallbackError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary.withValues(alpha: 0.45);

    return Container(
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = [
            if (constraints.maxWidth.isFinite) constraints.maxWidth,
            if (constraints.maxHeight.isFinite) constraints.maxHeight,
            if (width != null && width!.isFinite) width!,
            if (height != null && height!.isFinite) height!,
          ].fold<double>(96, (a, b) => a < b ? a : b);
          final showText = side >= 80;

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  color: color,
                  size: (side * 0.32).clamp(14, 48).toDouble(),
                ),
                if (showText) ...[
                  const SizedBox(height: 4),
                  Text(
                    'No image',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withAlpha(100),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // API Safety Guard: Handle null or empty image strings from backend
    final String? imageUrl = image?.trim();
    final bool isInvalid = imageUrl == null || imageUrl.isEmpty;

    Widget child;

    if (isInvalid) {
      child = errorBuilder != null
          ? errorBuilder!(context, Exception('Empty image URL'), null)
          : _buildFallbackError(context);
    } else {
      child = switch (type) {
        ImageType.asset => Image.asset(
          imageUrl,
          fit: fit,
          alignment: alignment ?? Alignment.center,
          errorBuilder: errorBuilder ?? (ctx, _, _) => _buildFallbackError(ctx),
        ),
        ImageType.network => CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          alignment: alignment ?? Alignment.center,
          placeholder: placeholder ?? (ctx, _) => _buildPlaceholder(ctx),
          errorWidget: (ctx, _, error) => errorBuilder != null
              ? errorBuilder!(ctx, error, null)
              : _buildFallbackError(ctx),
        ),
        ImageType.file => Image.file(
          File(imageUrl),
          fit: fit,
          alignment: alignment ?? Alignment.center,
          errorBuilder: errorBuilder ?? (ctx, _, _) => _buildFallbackError(ctx),
        ),
      };
    }

    final isAvatar = variant == ImageVariant.avatar;

    return Container(
      width: width,
      height: height,
      padding: padding != null ? EdgeInsets.all(padding!) : null,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background ? backgroundColor : Colors.transparent,
        shape: isAvatar ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isAvatar ? null : _borderRadius,
      ),
      child: child,
    );
  }
}
