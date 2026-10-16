import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../provider/profile_provider.dart';

/// Change name, username, email, photo and password.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _fullname = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();

  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _showPasswords = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().profile;
    _fullname.text = user?.fullname ?? '';
    _username.text = user?.username ?? '';
    _email.text = user?.email ?? '';
  }

  @override
  void dispose() {
    for (final controller in [
      _fullname,
      _username,
      _email,
      _currentPassword,
      _newPassword,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.gallery),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Iconsax.camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } catch (_) {
      _toast('Could not open the ${source.name}.');
      return;
    }
    if (picked == null || !mounted) return;

    final error = await context.read<ProfileProvider>().uploadAvatar(
      picked.path,
    );
    if (!mounted) return;
    _toast(error ?? 'Photo updated.');
  }

  Future<void> _saveDetails() async {
    FocusScope.of(context).unfocus();
    final fullname = _fullname.text.trim();
    final username = _username.text.trim();
    final email = _email.text.trim();

    if (fullname.isEmpty || username.isEmpty || email.isEmpty) {
      _toast('Please fill in your name, username and email.');
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9_.]{3,30}$').hasMatch(username)) {
      _toast('Username must be 3 to 30 letters, numbers, dots or underscores.');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _toast('That email address does not look right.');
      return;
    }

    final error = await context.read<ProfileProvider>().updateProfile(
      fullname: fullname,
      username: username,
      email: email,
    );
    if (!mounted) return;
    _toast(error ?? 'Profile saved.');
  }

  Future<void> _savePassword() async {
    FocusScope.of(context).unfocus();
    final newPassword = _newPassword.text;
    final strong =
        newPassword.length >= 8 &&
        RegExp('[A-Za-z]').hasMatch(newPassword) &&
        RegExp(r'\d').hasMatch(newPassword) &&
        RegExp('[^A-Za-z0-9]').hasMatch(newPassword);

    if (_currentPassword.text.isEmpty) {
      _toast('Enter your current password.');
      return;
    }
    if (!strong) {
      _toast(
        'New password needs at least 8 characters, '
        'with a letter, a number and a symbol.',
      );
      return;
    }
    if (newPassword != _confirmPassword.text) {
      _toast('The two new passwords do not match.');
      return;
    }

    final error = await context.read<ProfileProvider>().changePassword(
      currentPassword: _currentPassword.text,
      newPassword: newPassword,
    );
    if (!mounted) return;
    if (error == null) {
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }
    _toast(error ?? 'Password changed.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final provider = context.watch<ProfileProvider>();
    final user = provider.profile;
    final busy = provider.isSaving;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: const Center(child: Text('Please sign in first.')),
      );
    }

    final photo = user.profile;
    final initial = user.fullname.isNotEmpty
        ? user.fullname[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: AppBody(
        children: [
          // ── Photo ──
          Center(
            child: GestureDetector(
              onTap: busy ? null : _changePhoto,
              child: Stack(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: photo != null && photo.isNotEmpty
                        ? AppImage(
                            // A new key shows the new photo straight away.
                            key: ValueKey(photo),
                            image: photo,
                            variant: ImageVariant.avatar,
                            width: 104,
                            height: 104,
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Iconsax.camera,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConst.spaceSM),
          Center(
            child: TextButton(
              onPressed: busy ? null : _changePhoto,
              child: const Text('Change photo'),
            ),
          ),

          const SizedBox(height: AppConst.spaceLG),

          // ── Details ──
          Text('Your details', style: textTheme.titleMedium),
          const SizedBox(height: AppConst.spaceMD),
          AppTextfield(
            controller: _fullname,
            labelText: 'Full name',
            prefixIcon: const Icon(Iconsax.user, size: 20),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppConst.spaceMD),
          AppTextfield(
            controller: _username,
            labelText: 'Username',
            prefixIcon: const Icon(Iconsax.tag, size: 20),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppConst.spaceMD),
          AppTextfield(
            controller: _email,
            labelText: 'Email',
            prefixIcon: const Icon(Iconsax.sms, size: 20),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppConst.spaceLG),
          AppButton(
            'Save changes',
            isLoading: busy,
            onTap: busy ? null : _saveDetails,
          ),

          const SizedBox(height: AppConst.spaceXL),
          Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: AppConst.spaceMD),

          // ── Password ──
          Row(
            children: [
              Expanded(
                child: Text('Change password', style: textTheme.titleMedium),
              ),
              IconButton(
                tooltip: _showPasswords ? 'Hide' : 'Show',
                onPressed: () =>
                    setState(() => _showPasswords = !_showPasswords),
                icon: Icon(
                  _showPasswords ? Iconsax.eye_slash : Iconsax.eye,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConst.spaceSM),
          AppTextfield(
            controller: _currentPassword,
            labelText: 'Current password',
            prefixIcon: const Icon(Iconsax.lock, size: 20),
            obscureText: !_showPasswords,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppConst.spaceMD),
          AppTextfield(
            controller: _newPassword,
            labelText: 'New password',
            prefixIcon: const Icon(Iconsax.lock_1, size: 20),
            obscureText: !_showPasswords,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppConst.spaceMD),
          AppTextfield(
            controller: _confirmPassword,
            labelText: 'Confirm new password',
            prefixIcon: const Icon(Iconsax.lock_1, size: 20),
            obscureText: !_showPasswords,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppConst.spaceXS),
          Text(
            'Signed up with Google? Your account has no password here, '
            'so keep using "Continue with Google".',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConst.spaceLG),
          AppButton(
            'Change password',
            variant: ButtonVariant.outline,
            onTap: busy ? null : _savePassword,
          ),
          const SizedBox(height: AppConst.spaceXL),
        ],
      ),
    );
  }
}
