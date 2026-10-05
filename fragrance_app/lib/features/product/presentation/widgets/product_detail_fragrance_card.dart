import 'package:flutter/material.dart';

import '../../data/model/fragrance_model.dart';
import '../../data/model/fragrance_notes_model.dart';
import '../../data/model/product_info_model.dart';

class ProductDetailFragranceCard extends StatelessWidget {
  final FragranceModel fragrance;
  final FragranceNotesModel notes;
  final ProductInfoModel info;

  const new({
    super.key,
    required this.fragrance,
    required this.notes,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.opacity_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fragrance Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Fragrance Metadata
          _buildDetailRow(context, 'Concentration', fragrance.concentration),
          const SizedBox(height: 8),
          _buildDetailRow(context, 'Family', fragrance.fragranceFamily),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            'Gender',
            fragrance.gender.name.toUpperCase(),
          ),
          if (fragrance.releaseYear != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Release Year',
              fragrance.releaseYear.toString(),
            ),
          ],

          const Divider(height: 24),

          // Fragrance Pyramid Notes
          if (notes.top.isNotEmpty) ...[
            _buildDetailRow(context, 'Top Notes', notes.top.join(', ')),
            const SizedBox(height: 8),
          ],
          if (notes.middle.isNotEmpty) ...[
            _buildDetailRow(context, 'Heart Notes', notes.middle.join(', ')),
            const SizedBox(height: 8),
          ],
          if (notes.base.isNotEmpty) ...[
            _buildDetailRow(context, 'Base Notes', notes.base.join(', ')),
          ],

          // Product Usage / Details (If available)
          if (info.howToUse.isNotEmpty ||
              info.ingredients.isNotEmpty ||
              info.warnings.isNotEmpty) ...[
            const Divider(height: 24),
            if (info.howToUse.isNotEmpty) ...[
              _buildDetailRow(context, 'How to Use', info.howToUse.join('\n')),
              const SizedBox(height: 8),
            ],
            if (info.ingredients.isNotEmpty) ...[
              _buildDetailRow(
                context,
                'Ingredients',
                info.ingredients.join(', '),
              ),
              const SizedBox(height: 8),
            ],
            if (info.warnings.isNotEmpty) ...[
              _buildDetailRow(context, 'Warnings', info.warnings.join(', ')),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
