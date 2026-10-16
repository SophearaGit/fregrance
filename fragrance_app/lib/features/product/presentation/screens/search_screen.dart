import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../data/model/product_model.dart';
import '../provider/search_provider.dart';
import '../widgets/product_card.dart';

/// Search products by name, house (brand), note, mood, occasion or scent family.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<SearchProvider>();
      provider.clear();
      if (widget.initialQuery.trim().isNotEmpty) {
        unawaited(provider.searchNow(widget.initialQuery));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<SearchProvider>();

    final border = OutlineInputBorder(
      borderRadius: AppConst.borderRadiusMD,
      borderSide: BorderSide.none,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: provider.onQueryChanged,
          onSubmitted: (value) => unawaited(provider.searchNow(value)),
          style: textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search scents, notes, houses...',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Iconsax.search_normal_1,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _controller.clear();
                      provider.onQueryChanged('');
                    },
                  ),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConst.spaceMD,
              vertical: 12,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: AppConst.borderRadiusMD,
              borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
            ),
          ),
        ),
        actions: const [SizedBox(width: AppConst.spaceMD)],
      ),
      body: Column(
        children: [
          // Thin bar while a search is running
          SizedBox(
            height: 2,
            child: provider.isLoading
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
          Expanded(child: _buildResults(context, provider)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchProvider provider) {
    if (provider.query.isEmpty) {
      return const _SearchMessage(
        icon: Icons.search_rounded,
        title: 'Find your scent',
        subtitle:
            'Search by name, house, note or scent family, '
            'for example "Chanel", "vanilla" or "woody".',
      );
    }

    if (provider.results.isEmpty) {
      if (!provider.hasSearched) {
        return const Center(child: CircularProgressIndicator());
      }
      if (provider.error != null) {
        return const _SearchMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Search is not available',
          subtitle: 'Check that Laragon is running, then try again.',
        );
      }
      return _SearchMessage(
        icon: Icons.search_off_rounded,
        title: 'No scents found',
        subtitle: 'Nothing matches "${provider.query}". Try another word.',
      );
    }

    return AppPagination(
      isLoading: provider.isLoading,
      hasMore: provider.hasMore,
      onLoadMore: () => unawaited(provider.loadMore()),
      builder: (context, scrollController) {
        return Padding(
          padding: AppConst.paddingScreen,
          child: AppGridBuilder<ProductModel>(
            controller: scrollController,
            items: provider.results,
            itemBuilder: (context, product, index) {
              return ProductCard(product: product);
            },
          ),
        );
      },
    );
  }
}

// ===========================================================
// Empty, no-result and error message
// ===========================================================
class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConst.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: AppConst.spaceMD),
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: AppConst.spaceSM),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
