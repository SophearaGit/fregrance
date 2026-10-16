import '../../data/model/auth_response_model.dart';

abstract interface class AuthRepository {
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

  Future<String> getGoogleClientId();

  Future<AuthResponseModel> loginWithGoogle(String idToken);
}
