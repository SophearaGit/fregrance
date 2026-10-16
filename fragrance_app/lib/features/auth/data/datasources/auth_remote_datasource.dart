import '../../../../core/core.dart';
import '../model/auth_response_model.dart';
import 'auth_endpoint.dart';

abstract interface class AuthRemoteDatasource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<AuthResponseModel> register({
    required String fullname,
    required String username,
    required String email,
    required String password,
  });

  /// The Web client ID set in fragrance_backend/google-config.php ('' = off).
  Future<String> getGoogleClientId();

  /// Swap a Google ID token for this shop's login token.
  Future<AuthResponseModel> loginWithGoogle(String idToken);
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

  @override
  Future<AuthResponseModel> register({
    required String fullname,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      path: AuthEndpoint.register,
      data: {
        'fullname': fullname,
        'username': username,
        'email': email,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(response.data!);
  }

  @override
  Future<String> getGoogleClientId() async {
    final response = await _apiClient.get(path: AuthEndpoint.googleConfig);
    final data = response.data?['data'];
    final clientId = data is Map<String, dynamic> ? data['clientId'] : null;
    return clientId is String ? clientId : '';
  }

  @override
  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    final response = await _apiClient.post(
      path: AuthEndpoint.google,
      data: {'idToken': idToken},
    );
    return AuthResponseModel.fromJson(response.data!);
  }
}
