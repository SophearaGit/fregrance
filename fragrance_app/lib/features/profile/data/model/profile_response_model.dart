import '../../../../core/network/api_base_model.dart';

final class ProfileResponseModel extends ApiBaseModel {
  final String fullname;
  final String username;
  final String email;
  final String role;
  final String? profile;

  const ProfileResponseModel({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.fullname,
    required this.username,
    required this.email,
    required this.role,
    this.profile,
  });

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return ProfileResponseModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      fullname: json['fullname'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      profile: json['profile'] as String?,
    );
  }
}
