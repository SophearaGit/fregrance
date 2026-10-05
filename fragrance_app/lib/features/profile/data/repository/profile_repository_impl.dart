import '../../domain/repository/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../model/profile_response_model.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;

  const ProfileRepositoryImpl(this._remoteDatasource);

  @override
  Future<ProfileResponseModel> getUser() async => _remoteDatasource.getUser();
}
