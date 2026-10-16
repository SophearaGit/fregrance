import 'dart:developer';

import '../../../../core/core.dart';
import '../../data/model/profile_response_model.dart';
import '../../domain/repository/profile_repository.dart';

class ProfileProvider extends AppProvider {
  final ProfileRepository _profileRepository;

  ProfileProvider(this._profileRepository);

  ProfileResponseModel? _profile;
  double? _walletBalance;
  bool _isSaving = false;

  ProfileResponseModel? get profile => _profile;

  /// Null until loaded (or for admins, who have no wallet).
  double? get walletBalance => _walletBalance;

  /// True while a save, photo upload or password change is running.
  bool get isSaving => _isSaving;

  /// Load the signed-in user and their wallet balance.
  Future<void> getProfile() async => execute(
    () async {
      if (!AuthPreferences.isAuthenticated) return;
      _profile = await _profileRepository.getUser();
      await refreshWallet();
    },
    onError: (Object error) {
      log('getProfile error: $error');
      setError(_friendly(error));
    },
  );

  /// Reload just the wallet balance (e.g. after an order).
  Future<void> refreshWallet() async {
    try {
      _walletBalance = await _profileRepository.getWalletBalance();
    } catch (error) {
      log('wallet error: $error');
    }
    notifyListeners();
  }

  /// Save new details. Returns null when it worked, otherwise the reason.
  Future<String?> updateProfile({
    required String fullname,
    required String username,
    required String email,
  }) => _save(() async {
    _profile = await _profileRepository.updateUser(
      fullname: fullname.trim(),
      username: username.trim().toLowerCase(),
      email: email.trim().toLowerCase(),
    );
  });

  /// Upload a new profile photo from [filePath].
  Future<String?> uploadAvatar(String filePath) => _save(() async {
    _profile = await _profileRepository.uploadAvatar(filePath);
  });

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _save(
    () => _profileRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  Future<void> clearProfile() async => execute(() async {
    _profile = null;
    _walletBalance = null;
  });

  Future<String?> _save(Future<void> Function() action) async {
    if (_isSaving) return null;
    _isSaving = true;
    notifyListeners();
    try {
      await action();
      return null;
    } catch (error) {
      log('profile save error: $error');
      return _friendly(error);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String _friendly(Object error) => error is ApiException
      ? error.message
      : 'Could not reach the shop. Is Laragon running?';
}
