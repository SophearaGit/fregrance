import '../../data/model/profile_response_model.dart';

abstract interface class ProfileRepository {
  Future<ProfileResponseModel> getUser();

  Future<ProfileResponseModel> updateUser({
    required String fullname,
    required String username,
    required String email,
  });

  Future<ProfileResponseModel> uploadAvatar(String filePath);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<double> getWalletBalance();
}
