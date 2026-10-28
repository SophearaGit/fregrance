import '../../../../core/core.dart';
import '../model/address_model.dart';

/// The fields the customer fills in (label and postal code are optional).
typedef AddressInput = ({
  String label,
  String name,
  String phone,
  String addressLine,
  String city,
  String province,
  String postalCode,
  bool isDefault,
});

abstract interface class AddressRemoteDatasource {
  Future<List<AddressModel>> getAddresses();
  Future<AddressModel> create(AddressInput input);
  Future<AddressModel> update(String id, AddressInput input);
  Future<void> setDefault(String id);
  Future<void> delete(String id);
}

final class AddressRemoteDatasourceImpl implements AddressRemoteDatasource {
  final ApiClient _apiClient;

  const AddressRemoteDatasourceImpl(this._apiClient);

  Map<String, Object> _body(AddressInput input) => {
    'label': input.label,
    'name': input.name,
    'phone': input.phone,
    'addressLine': input.addressLine,
    'city': input.city,
    'province': input.province,
    'postalCode': input.postalCode,
    'isDefault': input.isDefault,
  };

  AddressModel _one(Map<String, dynamic>? body) =>
      AddressModel.fromJson(body!['data'] as Map<String, dynamic>);

  @override
  Future<List<AddressModel>> getAddresses() async {
    final response = await _apiClient.get(path: '/address');
    final data = response.data?['data'];
    return [
      if (data is List)
        for (final item in data)
          AddressModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<AddressModel> create(AddressInput input) async => _one(
    (await _apiClient.post(path: '/address/add', data: _body(input))).data,
  );

  @override
  Future<AddressModel> update(String id, AddressInput input) async => _one(
    (await _apiClient.post(path: '/address/$id/update', data: _body(input)))
        .data,
  );

  @override
  Future<void> setDefault(String id) async {
    await _apiClient.post(path: '/address/$id/default');
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.post(path: '/address/$id/delete');
  }
}
