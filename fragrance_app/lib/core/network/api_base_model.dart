abstract class ApiBaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApiBaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });
}
