import 'product_enum.dart';

final class FragranceModel {
  final String concentration;
  final ProductGender gender;
  final String fragranceFamily;
  final int? releaseYear;

  const FragranceModel({
    required this.concentration,
    required this.gender,
    required this.fragranceFamily,
    this.releaseYear,
  });

  factory FragranceModel.fromJson(Map<String, dynamic> json) {
    return FragranceModel(
      concentration: json['concentration'] as String,
      gender: ProductGender.values.byName(json['gender'] as String),
      fragranceFamily: json['fragranceFamily'] as String,
      releaseYear: json['releaseyear'] as int?,
    );
  }
}
