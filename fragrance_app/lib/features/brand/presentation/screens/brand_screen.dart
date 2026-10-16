import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../provider/brand_provider.dart';
import '../widgets/brand_grid_layout.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final brandProvider = context.read<BrandProvider>();
      await Future.wait([brandProvider.getBrands()]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Houses')),
      body: AppBody(
        children: [
          // ─────────────────────────────────────────
          // Search
          // ─────────────────────────────────────────
          _BrandSearchBar(onChanged: (value) => setState(() => _query = value)),

          const SizedBox(height: AppConst.spaceXL),

          BrandGridLayout(query: _query),
        ],
      ),
    );
  }
}

// ===========================================================
// Search Bar
// ===========================================================
class _BrandSearchBar extends StatelessWidget {
  const _BrandSearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      onChanged: onChanged,
      style: textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search houses...',
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Iconsax.search_normal_1,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConst.spaceMD,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppConst.borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConst.borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppConst.borderRadiusMD,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
      ),
    );
  }
}
