import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/core.dart';
import '../../domain/repository/auth_repository.dart';

class AuthProvider extends AppProvider {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  /// The Google client the plugin was set up with (null = not yet).
  static String? _googleClientId;

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
        onError: (Object error) {
          log('6. Error: ${error.toString()}');
          setError(_friendly(error));
        },
        onFinally: () => log('7. Finish'),
      );

  /// Create a customer account and sign in to it.
  Future<void> register({
    required String fullname,
    required String username,
    required String email,
    required String password,
  }) async => await execute(
    () async {
      final response = await _authRepository.register(
        fullname: fullname.trim(),
        username: username.trim().toLowerCase(),
        email: email.trim().toLowerCase(),
        password: password,
      );
      await AuthPreferences.setToken(response.token);
      _isAuthenticated = true;
    },
    onError: (Object error) {
      log('Register error: $error');
      setError(_friendly(error));
    },
  );

  /// Clear an old error, e.g. when opening another screen.
  void resetError() {
    if (error == null) return;
    setError(null);
  }

  String _friendly(Object error) => error is ApiException
      ? error.message
      : 'Could not reach the shop. Is Laragon running?';

  /// Sign in with the Google account on the phone. New customers get an
  /// account (and wallet) the first time.
  Future<void> loginWithGoogle() async => await execute(
    () async {
      final clientId = await _authRepository.getGoogleClientId();
      if (clientId.isEmpty) {
        setError(
          'Google sign-in is not set up yet. '
          'Add the client ID to fragrance_backend/google-config.php.',
        );
        return;
      }

      final google = GoogleSignIn.instance;
      if (_googleClientId != clientId) {
        // initialize may only run once per app start.
        if (_googleClientId != null) {
          setError('Google settings changed. Restart the app and try again.');
          return;
        }
        await google.initialize(serverClientId: clientId);
        _googleClientId = clientId;
      }

      final GoogleSignInAccount account;
      try {
        account = await google.authenticate();
      } on GoogleSignInException catch (error) {
        if (error.code == GoogleSignInExceptionCode.canceled) return;
        log('Google sign-in error: ${error.code} ${error.description}');
        setError('Google sign-in failed (${error.code.name}).');
        return;
      }

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        setError('Google did not return a sign-in token. Please try again.');
        return;
      }

      final response = await _authRepository.loginWithGoogle(idToken);
      await AuthPreferences.setToken(response.token);
      _isAuthenticated = true;
    },
    onError: (Object error) {
      log('Google login error: $error');
      setError(
        error is ApiException
            ? error.message
            : 'Google sign-in failed. Please try again.',
      );
    },
  );

  Future<void> logout() async => await execute(
    () async {
      log('1. Clearing local storage...');
      await AuthPreferences.clear();
      // Forget the Google account too, so the next sign-in can pick another.
      if (_googleClientId != null) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }

      log('2. Resetting local storage');
      _isAuthenticated = false;
    },
    onError: (Object error) => log('3. Error: ${error.toString()}'),
    onFinally: () => log('4. Finish'),
  );
}
