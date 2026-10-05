import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../product/data/model/product_model.dart';
import '../../../product/presentation/widgets/product_card.dart';
import '../provider/discovery_provider.dart';
import '../widgets/discovery_chip_row.dart';

class DiscoveryProductsScreen extends StatelessWidget {
  const DiscoveryProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiscoveryProvider>();

    // Read query params (go_router style)
    final params = GoRouterState.of(context).uri.queryParameters;
    final title = params['title'] ?? 'Discover Scents';

    // Determine which category this screen is focused on
    final category = _resolveCategory(params);

    // Apply initial filter once when entering (no extra list fetching)
    // We use a post-frame callback via a small helper widget to keep this Stateless
    return _InitialFilterApplier(
      params: params,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              provider.clearFilters();
              context.pop();
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          title: Text(
            title.isNotEmpty
                ? '${title[0].toUpperCase()}${title.substring(1)}'
                : title,
          ),
          actions: [
            if (provider.hasAnyFilter)
              TextButton(
                onPressed: () => provider.clearFilters(),
                child: Text(
                  'Clear',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ── Category pin (only 1 list based on entry type) ──
            if (category != null)
              _CategoryPin(provider: provider, category: category),

            // ── Products grid ──────────────────────────────────
            Expanded(
              child: AppPagination(
                isLoading: provider.isLoadingProducts,
                hasMore: provider.hasMore,
                onLoadMore: () => provider.getDiscoveryProducts(loadMore: true),
                builder: (context, scrollController) {
                  if (provider.discoveryProducts.isEmpty) {
                    if (provider.isLoadingProducts) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.loading,
                          strokeWidth: 2.5,
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        'No scents found',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: AppConst.paddingScreen,
                    child: AppGridBuilder<ProductModel>(
                      controller: scrollController,
                      items: provider.discoveryProducts,
                      itemBuilder: (context, product, index) {
                        return ProductCard(product: product);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Decide which single list should appear in the pin.
  _CategoryType? _resolveCategory(Map<String, String> params) {
    if (params.containsKey('mood')) return _CategoryType.mood;
    if (params.containsKey('note')) return _CategoryType.note;
    if (params.containsKey('occasion')) return _CategoryType.occasion;
    if (params.containsKey('family')) return _CategoryType.family;
    if (params.containsKey('type')) return _CategoryType.type;
    // "See more" case – you can pass e.g. category=mood without a value
    final cat = params['category'];
    return switch (cat) {
      'mood' => _CategoryType.mood,
      'note' => _CategoryType.note,
      'occasion' => _CategoryType.occasion,
      'family' => _CategoryType.family,
      'type' => _CategoryType.type,
      _ => null,
    };
  }
}

// ===========================================================
// Apply initial filters only once (no extra initState in screen)
// ===========================================================
class _InitialFilterApplier extends StatefulWidget {
  const _InitialFilterApplier({required this.params, required this.child});

  final Map<String, String> params;
  final Widget child;

  @override
  State<_InitialFilterApplier> createState() => _InitialFilterApplierState();
}

class _InitialFilterApplierState extends State<_InitialFilterApplier> {
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_applied || !mounted) return;
      _applied = true;

      final provider = context.read<DiscoveryProvider>();
      provider.applyInitialFilters(
        mood: widget.params['mood'],
        note: widget.params['note'],
        occasion: widget.params['occasion'],
        family: widget.params['family'],
        type: widget.params['type'],
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ===========================================================
// Category types
// ===========================================================
enum _CategoryType { mood, note, occasion, family, type }

// ===========================================================
// Pinned category row – shows ONLY the relevant list
// ===========================================================
class _CategoryPin extends StatelessWidget {
  const _CategoryPin({required this.provider, required this.category});

  final DiscoveryProvider provider;
  final _CategoryType category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget? chipRow;

    switch (category) {
      case _CategoryType.mood:
        if (provider.moods.isEmpty) break;
        chipRow = DiscoveryChipRow<String>(
          items: provider.moods,
          labelBuilder: (m) => m,
          isSelectedBuilder: (m) => provider.selectedMood == m,
          onSelected: (m) async {
            provider.selectMood(provider.selectedMood == m ? null : m);
          },
        );
        break;

      case _CategoryType.note:
        // Adjust if notes is FragranceNotesModel instead of List<String>
        // For now assume you expose a flat list or handle inside DiscoveryNote
        break;

      case _CategoryType.occasion:
        if (provider.occasions.isEmpty) break;
        chipRow = DiscoveryChipRow<String>(
          items: provider.occasions,
          labelBuilder: (o) => o,
          isSelectedBuilder: (o) => provider.selectedOccasion == o,
          onSelected: (o) async {
            provider.selectOccasion(provider.selectedOccasion == o ? null : o);
          },
        );
        break;

      case _CategoryType.family:
        if (provider.scentFamilies.isEmpty) break;
        chipRow = DiscoveryChipRow<String>(
          items: provider.scentFamilies,
          labelBuilder: (f) => f,
          isSelectedBuilder: (f) => provider.selectedScentFamily == f,
          onSelected: (f) async {
            provider.selectFamily(provider.selectedScentFamily == f ? null : f);
          },
        );
        break;

      case _CategoryType.type:
        // Handle type list if you have one
        break;
    }

    if (chipRow == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
            width: 0.8,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConst.spaceMD,
        vertical: AppConst.spaceSM,
      ),
      child: chipRow,
    );
  }
}
