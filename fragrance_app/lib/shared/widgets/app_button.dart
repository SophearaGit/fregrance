import 'package:flutter/material.dart';

import '../../core/core.dart';

enum ButtonVariant { filled, outline, text }

final class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;
  final bool isLoading;
  final Color? color;
  final Color? textColor;

  const AppButton(
    this.text, {
    super.key,
    required this.onTap,
    this.variant = ButtonVariant.filled,
    this.icon,
    this.width,
    this.height = 52,
    this.isLoading = false,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isDisabled = onTap == null || isLoading;

    // Foreground
    final Color baseForeground =
        textColor ??
        switch (variant) {
          ButtonVariant.filled => colors.onPrimary,
          ButtonVariant.outline ||
          ButtonVariant.text => color ?? colors.primary,
        };

    final Color contentColor = isDisabled
        ? colors.onSurface.withValues(alpha: 0.38)
        : baseForeground;

    // Background
    final Color backgroundColor = switch (variant) {
      ButtonVariant.filled =>
        isDisabled
            ? colors.onSurface.withValues(alpha: 0.12)
            : color ?? colors.primary,
      ButtonVariant.outline || ButtonVariant.text => Colors.transparent,
    };

    // Border (outline only)
    final Border? border = variant == ButtonVariant.outline
        ? Border.all(
            color: isDisabled
                ? colors.onSurface.withValues(alpha: 0.12)
                : color ?? colors.primary,
          )
        : null;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: backgroundColor,
        borderRadius: AppConst.borderRadiusMD,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: AppConst.borderRadiusMD,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppConst.borderRadiusMD,
              border: border,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: contentColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: contentColor),
                          const SizedBox(width: AppConst.spaceSM),
                        ],
                        Text(
                          text,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: contentColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
