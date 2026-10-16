import '../../domain/repository/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../model/profile_response_model.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;

  const ProfileRepositoryImpl(this._remoteDatasource);

  @override
  Future<ProfileResponseModel> getUser() async => _remoteDatasource.getUser();

  @override
  Future<ProfileResponseModel> updateUser({
    required String fullname,
    required String username,
    required String email,
  }) => _remoteDatasource.updateUser(
    fullname: fullname,
    username: username,
    email: email,
  );

  @override
  Future<ProfileResponseModel> uploadAvatar(String filePath) =>
      _remoteDatasource.uploadAvatar(filePath);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _remoteDatasource.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  @override
  Future<double> getWalletBalance() => _remoteDatasource.getWalletBalance();
}
