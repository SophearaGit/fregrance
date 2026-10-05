final class ProductInfoModel {
  final List<String> ingredients;
  final List<String> howToUse;
  final List<String> warnings;

  const ProductInfoModel({
    required this.ingredients,
    required this.howToUse,
    required this.warnings,
  });

  factory ProductInfoModel.fromJson(Map<String, dynamic> json) {
    return ProductInfoModel(
      ingredients: json['ingredients'] is List
          ? (json['ingredients'] as List).map((e) => e.toString()).toList()
          : const [],
      howToUse: json['howToUse'] is List
          ? (json['howToUse'] as List).map((e) => e.toString()).toList()
          : const [],
      warnings: json['warnings'] is List
          ? (json['warnings'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}
