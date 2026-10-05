import '../../../product/data/model/product_model.dart';

final class FeaturedModel {
  final ProductModel? newArrival;
  final ProductModel? topSales;
  final ProductModel? trending;

  const FeaturedModel({this.newArrival, this.topSales, this.trending});

  factory FeaturedModel.fromJson(Map<String, dynamic> json) {
    return FeaturedModel(
      newArrival: json['newArrival'] != null
          ? ProductModel.fromJson(json['newArrival'] as Map<String, dynamic>)
          : null,
      topSales: json['topSales'] != null
          ? ProductModel.fromJson(json['topSales'] as Map<String, dynamic>)
          : null,
      trending: json['trending'] != null
          ? ProductModel.fromJson(json['trending'] as Map<String, dynamic>)
          : null,
    );
  }
}
