import '../../../../core/core.dart';
import 'fragrance_model.dart';
import 'fragrance_notes_model.dart';
import 'product_enum.dart';
import 'product_info_model.dart';

final class ProductModel extends ApiBaseModel {
  // =========================================
  // Basic Info
  // =========================================
  final String name;
  final String brand;
  final String? brandImage;
  final String? description;
  final ProductStatus status;
  final String? size;

  // =========================================
  // Media
  // =========================================
  final List<String> images;
  final int? defaultImageIndex;

  // =========================================
  // Pricing & Stock
  // =========================================
  final double price; // Original Price
  final double? discount; // 0–100 (% ONLY)
  final String currency;
  final int stock;
  final int salesCount;

  // =========================================
  // Discovery & Filtering
  // =========================================
  final double? rating;
  final List<String>? moods;
  final List<String>? occasions;
  final List<String>? tags;

  // =========================================
  // Fragrance Details
  // =========================================
  final FragranceModel fragrance;
  final FragranceNotesModel fragranceNotes;
  final ProductInfoModel productInfo;

  const ProductModel({
    // Super
    required super.id,
    required super.createdAt,
    required super.updatedAt,

    // Basic Info
    required this.name,
    required this.brand,
    this.brandImage,
    this.description,
    required this.status,
    this.size,

    // Media
    required this.images,
    this.defaultImageIndex,

    // Pricing & Stock
    required this.price,
    this.discount,
    required this.currency,
    required this.stock,
    required this.salesCount,
    // Discovery & Filtering
    this.rating,
    this.moods,
    this.occasions,
    this.tags,

    // Fragrance Details
    required this.fragrance,
    required this.fragranceNotes,
    required this.productInfo,
  });

  /// The API sends "out_of_stock", while the enum value is named outOfStock.
  static ProductStatus _parseStatus(String? value) {
    switch (value) {
      case 'inactive':
        return ProductStatus.inactive;
      case 'out_of_stock':
      case 'outOfStock':
        return ProductStatus.outOfStock;
      default:
        return ProductStatus.active;
    }
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String,
      brand: json['brand'] as String,
      brandImage: json['brandImage'] as String?,
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String?),
      size: json['size'] as String?,

      // 🛡️ Safe list extraction
      images: json['images'] is List
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : const [],
      defaultImageIndex: json['defaultImageIndex'] as int?,

      price: (json['price'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      currency: json['currency'] as String,
      stock: json['stock'] as int,
      salesCount: json['salesCount'] as int,

      rating: (json['rating'] as num?)?.toDouble(),
      moods: json['moods'] is List
          ? (json['moods'] as List).map((e) => e.toString()).toList()
          : null,
      occasions: json['occasions'] is List
          ? (json['occasions'] as List).map((e) => e.toString()).toList()
          : null,
      tags: json['tags'] is List
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : null,

      fragrance: FragranceModel.fromJson(
        json['fragrance'] as Map<String, dynamic>,
      ),
      fragranceNotes: FragranceNotesModel.fromJson(
        json['fragranceNotes'] as Map<String, dynamic>,
      ),
      productInfo: ProductInfoModel.fromJson(
        json['productInfo'] as Map<String, dynamic>,
      ),
    );
  }

  /// Safe getter that resolves the active default image URL
  String? get defaultImage {
    if (images.isEmpty) return null; // Safe for empty array []

    final index = defaultImageIndex ?? 0;

    // Bounds check to avoid RangeError
    if (index >= 0 && index < images.length) {
      return images[index];
    }

    return images.first; // Fallback if index is out of bounds
  }
}
