import '../../data/model/profile_response_model.dart';

abstract interface class ProfileRepository {
  Future<ProfileResponseModel> getUser();
}
