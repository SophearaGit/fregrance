import '../../../../core/core.dart';
import '../model/auth_response_model.dart';
import 'auth_endpoint.dart';

abstract interface class AuthRemoteDatasource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });
}

final class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasourceImpl(this._apiClient);

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      path: AuthEndpoint.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data!);
  }
}
