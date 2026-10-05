import 'package:flutter/material.dart';

import '../../core/core.dart';

class AppBody extends StatelessWidget {
  final List<Widget> children;
  final bool bottomPadding;
  final ScrollController? controller;

  const AppBody({
    super.key,
    required this.children,
    this.bottomPadding = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return
    // Note: If AppBody already returns a Scaffold, but your Screen *also* returns a Scaffold,
    // you might want to double check if you have nested Scaffolds.
    // Usually, AppBody is just the body content, but let's keep your structure:
    SingleChildScrollView(
      controller: controller,
      padding: AppConst.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...children, if (bottomPadding) const SizedBox(height: 110)],
      ),
    );
  }
}
