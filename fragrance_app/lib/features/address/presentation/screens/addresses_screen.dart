import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../data/model/address_model.dart';
import '../provider/address_provider.dart';

/// "My addresses". With [pick] true (from the cart), tapping an address
/// chooses it for the order and goes back.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key, this.pick = false});

  final bool pick;

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async => context.read<AddressProvider>().loadAddresses(),
    );
  }

  Future<void> _openForm([AddressModel? address]) async {
    final saved = await context.push<bool>(Routes.addressForm, extra: address);
    if (saved == true && mounted && widget.pick && address == null) {
      // A new address added while choosing one: use it straight away.
      final chosen = context.read<AddressProvider>().selected;
      if (chosen != null) context.pop(chosen);
    }
  }

  Future<void> _delete(AddressModel address) async {
    final provider = context.read<AddressProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('${address.title}\n${address.oneLine}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await provider.delete(address);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Address deleted.')),
    );
  }

  Future<void> _makeDefault(AddressModel address) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AddressProvider>().setDefault(address);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? '${address.title} is now your default.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();
    final addresses = provider.addresses;
    final selectedId = provider.selected?.id;

    Widget body;
    if (!AuthPreferences.isAuthenticated) {
      body = _Message(
        icon: Iconsax.location,
        title: 'Sign in to save your addresses',
        action: AppButton(
          'Sign in',
          width: 160,
          onTap: () => context.push(Routes.login),
        ),
      );
    } else if (provider.isLoading && addresses.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && addresses.isEmpty) {
      body = _Message(
        icon: Iconsax.warning_2,
        title: provider.error!,
        action: AppButton(
          'Try again',
          width: 160,
          onTap: provider.loadAddresses,
        ),
      );
    } else if (addresses.isEmpty) {
      body = _Message(
        icon: Icons.add_location_alt_outlined,
        title: 'No addresses yet',
        subtitle: 'Add where we should deliver your orders.',
        action: AppButton(
          'Add address',
          icon: Iconsax.add,
          width: 190,
          onTap: _openForm,
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: provider.loadAddresses,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppConst.spaceMD,
            AppConst.spaceMD,
            AppConst.spaceMD,
            100,
          ),
          itemCount: addresses.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppConst.spaceMD),
          itemBuilder: (context, index) {
            final address = addresses[index];
            return _AddressCard(
              address: address,
              selected: widget.pick && address.id == selectedId,
              onTap: widget.pick
                  ? () {
                      provider.select(address);
                      context.pop(address);
                    }
                  : () => _openForm(address),
              onEdit: () => _openForm(address),
              onDelete: () => _delete(address),
              onMakeDefault: address.isDefault
                  ? null
                  : () => _makeDefault(address),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pick ? 'Deliver to' : 'My addresses'),
      ),
      body: body,
      floatingActionButton:
          AuthPreferences.isAuthenticated && addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: provider.isSaving ? null : _openForm,
              icon: const Icon(Iconsax.add),
              label: const Text('Add address'),
            )
          : null,
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onMakeDefault,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMakeDefault;

  IconData get _icon => switch (address.label.toLowerCase()) {
    'home' => Iconsax.home_2,
    'work' || 'office' => Icons.work_outline_rounded,
    _ => Iconsax.location,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppConst.borderRadiusLG,
        side: BorderSide(
          color: selected ? colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: AppConst.borderRadiusLG,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConst.spaceMD,
            AppConst.spaceMD,
            AppConst.spaceXS,
            AppConst.spaceMD,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: AppConst.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          address.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: AppConst.borderRadiusFull,
                            ),
                            child: Text(
                              'Default',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address.name} · ${address.phone}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(address.oneLine, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 4),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'default') {
                    onMakeDefault?.call();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onMakeDefault != null)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as default'),
                    ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConst.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(height: AppConst.spaceMD),
            Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppConst.spaceSM),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppConst.spaceLG),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
