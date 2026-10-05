import 'package:flutter/material.dart';

import '../../../../core/core.dart';

class CartQuantityButton extends StatelessWidget {
  const CartQuantityButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppConst.borderRadiusFull,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withAlpha(50),
        ),
      ),
    );
  }
}
