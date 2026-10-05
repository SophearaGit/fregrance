import 'dart:developer';

import '../../../../core/core.dart';
import '../../domain/repository/auth_repository.dart';

class AuthProvider extends AppProvider {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> initialize() async {
    final token = AuthPreferences.token;

    if (token == null) {
      _isAuthenticated = false;
      return;
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async =>
      await execute(
        () async {
          //  Fields Validation
          log('1. Validation');
          if (email.trim().isEmpty && password.isEmpty) {
            log('Missing fields. Please provide email and password.');
            setError('Missing fields. Please provide email and password.');
            return;
          }

          log('2. Executing login...');
          final response = await _authRepository.login(
            email: email,
            password: password,
          );
          log('3. Checking repository...');

          await AuthPreferences.setToken(response.token);
          log('4.  Setting token...');

          _isAuthenticated = true;
          log('5. Setting to local storage');
        },
        onError: (Object error) => log('6. Error: ${error.toString()}'),
        onFinally: () => log('7. Finish'),
      );

  Future<void> logout() async => await execute(
    () async {
      log('1. Clearing local storage...');
      await AuthPreferences.clear();

      log('2. Resetting local storage');
      _isAuthenticated = false;
    },
    onError: (Object error) => log('3. Error: ${error.toString()}'),
    onFinally: () => log('4. Finish'),
  );
}
