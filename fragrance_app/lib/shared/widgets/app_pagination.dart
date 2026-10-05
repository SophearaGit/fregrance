import 'package:flutter/material.dart';

class AppPagination extends StatefulWidget {
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  // Exposes the scroll controller down to the child builder
  final Widget Function(
    BuildContext context,
    ScrollController? scrollController,
  )
  builder;
  final ScrollController? controller;

  const AppPagination({
    super.key,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.builder,
    this.controller,
  });

  @override
  State<AppPagination> createState() => _AppPaginationState();
}

class _AppPaginationState extends State<AppPagination> {
  late final ScrollController _internalController;

  ScrollController get _activeController =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = ScrollController();
    _activeController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _activeController.removeListener(_onScroll);
    if (widget.controller == null) _internalController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_activeController.hasClients &&
        _activeController.position.pixels >=
            _activeController.position.maxScrollExtent - 200) {
      if (!widget.isLoading && widget.hasMore) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.controller == null ? _activeController : null,
    );
  }
}
