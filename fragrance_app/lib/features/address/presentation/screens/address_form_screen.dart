import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../profile/presentation/provider/profile_provider.dart';
import '../../data/model/address_model.dart';
import '../provider/address_provider.dart';

/// Add a new address, or edit [address]. Pops `true` after saving.
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.address});

  final AddressModel? address;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  static const _labels = ['Home', 'Work', 'Other'];

  /// Cambodia's capital and 24 provinces.
  static const _provinces = [
    'Phnom Penh', 'Banteay Meanchey', 'Battambang', 'Kampong Cham',
    'Kampong Chhnang', 'Kampong Speu', 'Kampong Thom', 'Kampot', 'Kandal',
    'Kep', 'Koh Kong', 'Kratie', 'Mondulkiri', 'Oddar Meanchey', 'Pailin',
    'Preah Sihanouk', 'Preah Vihear', 'Prey Veng', 'Pursat', 'Ratanakiri',
    'Siem Reap', 'Stung Treng', 'Svay Rieng', 'Takeo', 'Tboung Khmum',
  ];

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _postal;
  late String _label;
  String? _province;
  late bool _isDefault;
  String? _error;

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    final profileName = context.read<ProfileProvider>().profile?.fullname ?? '';
    _name = TextEditingController(text: a?.name ?? profileName);
    _phone = TextEditingController(text: a?.phone ?? '');
    _street = TextEditingController(text: a?.addressLine ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _label = a?.label ?? 'Home';
    _province = a == null ? 'Phnom Penh' : a.province;
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _street, _city, _postal]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    final missing = <String>[
      if (_name.text.trim().isEmpty) 'receiver name',
      if (_phone.text.trim().isEmpty) 'phone number',
      if (_street.text.trim().isEmpty) 'street address',
      if (_city.text.trim().isEmpty) 'city / district',
      if ((_province ?? '').isEmpty) 'province',
    ];
    if (missing.isNotEmpty) return 'Please fill in the ${missing.join(', ')}.';
    if (!RegExp(r'^[0-9+()\s-]{6,20}$').hasMatch(_phone.text.trim())) {
      return 'That phone number does not look right.';
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final problem = _validate();
    setState(() => _error = problem);
    if (problem != null) return;

    final error = await context.read<AddressProvider>().save(
      existing: widget.address,
      input: (
        label: _label,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        addressLine: _street.text.trim(),
        city: _city.text.trim(),
        province: _province ?? '',
        postalCode: _postal.text.trim(),
        isDefault: _isDefault,
      ),
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address saved.')),
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final busy = context.watch<AddressProvider>().isSaving;

    // Keep an old province that is not in the list (typed elsewhere).
    final provinces = [
      ..._provinces,
      if (_province != null && !_provinces.contains(_province)) _province!,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit address' : 'New address')),
      body: AppBody(
        children: [
          // ── Label ──
          Text('Save as', style: textTheme.titleSmall),
          const SizedBox(height: AppConst.spaceSM),
          Wrap(
            spacing: 8,
            children: [
              for (final label in _labels)
                ChoiceChip(
                  label: Text(label),
                  selected: _label == label,
                  onSelected: (_) => setState(() => _label = label),
                ),
            ],
          ),
          const SizedBox(height: AppConst.spaceLG),

          // ── Receiver ──
          Text('Receiver', style: textTheme.titleSmall),
          const SizedBox(height: AppConst.spaceSM),
          AppTextfield(
            controller: _name,
            labelText: 'Full name',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppConst.spaceMD),
          AppTextfield(
            controller: _phone,
            labelText: 'Phone number',
            hintText: '012 345 678',
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppConst.spaceLG),

          // ── Address ──
          Text('Address', style: textTheme.titleSmall),
          const SizedBox(height: AppConst.spaceSM),
          AppTextfield(
            controller: _street,
            labelText: 'House no., street',
            hintText: '#12, St 271',
            prefixIcon: const Icon(Icons.home_outlined, size: 20),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppConst.spaceMD),
          AppTextfield(
            controller: _city,
            labelText: 'Sangkat / Khan or city',
            hintText: 'Toul Kork',
            prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppConst.spaceMD),
          DropdownButtonFormField<String>(
            initialValue: _province,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Province',
              prefixIcon: const Icon(Icons.map_outlined, size: 20),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              for (final p in provinces)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (value) => setState(() => _province = value),
          ),
          const SizedBox(height: AppConst.spaceMD),
          AppTextfield(
            controller: _postal,
            labelText: 'Postal code (optional)',
            prefixIcon: const Icon(Icons.markunread_mailbox_outlined, size: 20),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppConst.spaceSM),

          // ── Default ──
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isDefault || (widget.address?.isDefault ?? false),
            onChanged: (widget.address?.isDefault ?? false)
                ? null // already the default
                : (value) => setState(() => _isDefault = value),
            title: const Text('Use as my default address'),
            subtitle: const Text('Orders are delivered here unless you pick another.'),
          ),

          if (_error != null) ...[
            const SizedBox(height: AppConst.spaceSM),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: AppConst.spaceLG),
          AppButton(
            _editing ? 'Save changes' : 'Save address',
            isLoading: busy,
            onTap: busy ? null : _save,
          ),
          const SizedBox(height: AppConst.spaceXL),
        ],
      ),
    );
  }
}
