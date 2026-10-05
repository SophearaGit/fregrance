import 'dart:developer';

import '../../../../core/core.dart';
import '../../data/model/profile_response_model.dart';
import '../../domain/repository/profile_repository.dart';

class ProfileProvider extends AppProvider {
  final ProfileRepository _profileRepository;

  ProfileProvider(this._profileRepository);

  ProfileResponseModel? _profile;

  ProfileResponseModel? get profile => _profile;

  Future<void> getProfile() async => execute(
    () async {
      log('1. Executing get user');
      final user = await _profileRepository.getUser();
      log('2. User received');
      _profile = user;
      log('3. Assign user');
    },
    onError: (Object error) => log('4. ${error.toString()}'),
    onFinally: () => log('5. Finish'),
  );

  Future<void> clearProfile() async => execute(() async => _profile = null);
}
