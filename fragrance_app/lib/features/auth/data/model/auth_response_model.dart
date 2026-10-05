final class AuthResponseModel {
  final String message;
  final String token;

  const AuthResponseModel({required this.message, required this.token});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      message: json['message'] as String,
      token: json['token'] as String,
    );
  }
}
