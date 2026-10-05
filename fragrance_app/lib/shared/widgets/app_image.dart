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

  Widget _buildFallbackError(BuildContext context) {
    // Ensure dimensions are present AND finite to prevent Infinity font size crashes
    final bool hasValidDimensions =
        width != null && height != null && width!.isFinite && height!.isFinite;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: hasValidDimensions ? (width! * 0.4) : 24.0,
        ),
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
