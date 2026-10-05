import 'package:flutter/material.dart';

import '../../core/core.dart';

class AppGridBuilder<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int crossAxisCount;
  final double childAspectRatio;

  const AppGridBuilder({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.62,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics:
          physics ??
          (shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.zero, // Let AppBody handle padding
      itemCount: items.length, // Purely items now, no +1 hack
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppConst.spaceMD,
        mainAxisSpacing: AppConst.spaceMD,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}
