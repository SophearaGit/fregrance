final class BrandModel {
  final String brand;
  final String image;

  const BrandModel({required this.brand, required this.image});

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      brand: json['brand'] as String,
      image: json['image'] as String,
    );
  }
}
