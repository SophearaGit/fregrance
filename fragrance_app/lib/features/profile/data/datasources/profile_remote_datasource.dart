import 'package:dio/dio.dart';

import '../../../../core/core.dart';
import '../model/profile_response_model.dart';
import 'profile_endpoint.dart';

abstract interface class ProfileRemoteDatasource {
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

final class ProfileRemoteDatasourceImpl extends ProfileRemoteDatasource {
  final ApiClient _apiClient;

  ProfileRemoteDatasourceImpl(this._apiClient);

  ProfileResponseModel _user(Response<Map<String, dynamic>> response) =>
      ProfileResponseModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );

  @override
  Future<ProfileResponseModel> getUser() async =>
      _user(await _apiClient.get(path: ProfileEndpoint.getUser));

  @override
  Future<ProfileResponseModel> updateUser({
    required String fullname,
    required String username,
    required String email,
  }) async => _user(
    await _apiClient.post(
      path: ProfileEndpoint.updateUser,
      data: {'fullname': fullname, 'username': username, 'email': email},
    ),
  );

  @override
  Future<ProfileResponseModel> uploadAvatar(String filePath) async => _user(
    await _apiClient.postForm(
      path: ProfileEndpoint.avatar,
      data: FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      }),
    ),
  );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      path: ProfileEndpoint.password,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<double> getWalletBalance() async {
    final response = await _apiClient.get(path: ProfileEndpoint.wallet);
    final data = response.data?['data'];
    final balance = data is Map<String, dynamic> ? data['balance'] : null;
    return balance is num ? balance.toDouble() : 0;
  }
}
