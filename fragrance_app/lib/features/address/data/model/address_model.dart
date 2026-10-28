/// A delivery address saved by the customer.
final class AddressModel {
  final String id;
  final String label; // "Home", "Work"... may be empty
  final String name; // who receives the parcel
  final String phone;
  final String addressLine;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['id'] as String,
    label: json['label'] as String? ?? '',
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    addressLine: json['addressLine'] as String? ?? '',
    city: json['city'] as String? ?? '',
    province: json['province'] as String? ?? '',
    postalCode: json['postalCode'] as String? ?? '',
    isDefault: json['isDefault'] as bool? ?? false,
  );

  /// "Home" when labelled, otherwise the receiver's name.
  String get title => label.isNotEmpty ? label : name;

  /// "#12, St 271, Toul Kork, Phnom Penh 12152"
  String get oneLine => [
    addressLine,
    city,
    [province, postalCode].where((p) => p.isNotEmpty).join(' '),
  ].where((p) => p.isNotEmpty).join(', ');

  /// What is saved on the order, so the shop knows where to deliver.
  String get deliveryText => '$name · $phone\n$oneLine';
}
