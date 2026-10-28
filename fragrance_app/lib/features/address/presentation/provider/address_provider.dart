import 'dart:developer';

import '../../../../core/core.dart';
import '../../data/datasources/address_remote_datasource.dart';
import '../../data/model/address_model.dart';

/// The customer's delivery addresses, and which one the next order goes to.
final class AddressProvider extends AppProvider {
  final AddressRemoteDatasource _datasource;

  AddressProvider(this._datasource);

  List<AddressModel> _addresses = [];
  String? _selectedId; // picked at checkout; falls back to the default
  String? _loadedFor; // the sign-in the list belongs to
  bool _isSaving = false;

  List<AddressModel> get addresses => _addresses;
  bool get isSaving => _isSaving;

  /// True once the list was fetched for the signed-in customer.
  bool get loaded =>
      _loadedFor != null && _loadedFor == AuthPreferences.token;

  /// The address the next order will be delivered to.
  AddressModel? get selected {
    if (_addresses.isEmpty) return null;
    for (final address in _addresses) {
      if (address.id == _selectedId) return address;
    }
    for (final address in _addresses) {
      if (address.isDefault) return address;
    }
    return _addresses.first;
  }

  void select(AddressModel address) {
    _selectedId = address.id;
    notifyListeners();
  }

  /// Load the list unless it is already loaded for this sign-in.
  Future<void> ensureLoaded() async {
    if (!loaded) await loadAddresses();
  }

  Future<void> loadAddresses() async => execute(
    () async {
      if (!AuthPreferences.isAuthenticated) {
        _addresses = [];
        _loadedFor = null;
        return;
      }
      if (_loadedFor != AuthPreferences.token) _selectedId = null;
      _addresses = await _datasource.getAddresses();
      _loadedFor = AuthPreferences.token;
    },
    onError: (Object error) {
      log('loadAddresses error: $error');
      setError(_friendly(error));
    },
  );

  /// Add ([existing] null) or edit an address. Returns null when it worked.
  Future<String?> save({
    AddressModel? existing,
    required AddressInput input,
  }) => _run(() async {
    final saved = existing == null
        ? await _datasource.create(input)
        : await _datasource.update(existing.id, input);
    _selectedId = saved.id;
    _addresses = await _datasource.getAddresses();
  });

  Future<String?> setDefault(AddressModel address) => _run(() async {
    await _datasource.setDefault(address.id);
    _addresses = await _datasource.getAddresses();
  });

  Future<String?> delete(AddressModel address) => _run(() async {
    await _datasource.delete(address.id);
    if (_selectedId == address.id) _selectedId = null;
    _addresses = await _datasource.getAddresses();
  });

  Future<String?> _run(Future<void> Function() action) async {
    if (_isSaving) return null;
    _isSaving = true;
    notifyListeners();
    try {
      await action();
      _loadedFor = AuthPreferences.token;
      return null;
    } catch (error) {
      log('address error: $error');
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
