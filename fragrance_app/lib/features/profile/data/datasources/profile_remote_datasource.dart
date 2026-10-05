import '../../../../core/core.dart';
import '../model/profile_response_model.dart';
import 'profile_endpoint.dart';

abstract interface class ProfileRemoteDatasource {
  Future<ProfileResponseModel> getUser();
}

final class ProfileRemoteDatasourceImpl extends ProfileRemoteDatasource {
  final ApiClient _apiClient;

  ProfileRemoteDatasourceImpl(this._apiClient);

  @override
  Future<ProfileResponseModel> getUser() async {
    final response = await _apiClient.get(path: ProfileEndpoint.getUser);

    return ProfileResponseModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
