import '../../domain/repository/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../model/auth_response_model.dart';

final class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  const AuthRepositoryImpl(this._remoteDatasource);

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async => _remoteDatasource.login(email: email, password: password);

  @override
  Future<AuthResponseModel> register({
    required String fullname,
    required String username,
    required String email,
    required String password,
  }) => _remoteDatasource.register(
    fullname: fullname,
    username: username,
    email: email,
    password: password,
  );

  @override
  Future<String> getGoogleClientId() => _remoteDatasource.getGoogleClientId();

  @override
  Future<AuthResponseModel> loginWithGoogle(String idToken) =>
      _remoteDatasource.loginWithGoogle(idToken);
}
