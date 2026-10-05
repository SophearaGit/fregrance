import 'package:flutter/material.dart';

/// ```dart
/// List<Widget> children;
/// String? title;
/// EdgeInsetsGeometry padding;
/// EdgeInsetsGeometry margin;
/// double spacing;
/// Color? bgColor;
/// BorderRadiusGeometry borderRadius;
/// ```
final class AppSection extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double spacing;
  final Color? bgColor;
  final BorderRadiusGeometry borderRadius;

  const AppSection({
    super.key,
    required this.children,
    this.title,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.spacing = 8,
    this.bgColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Content box
          Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor ?? colorScheme.surfaceContainer,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: spacing),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
