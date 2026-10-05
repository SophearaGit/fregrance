import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../provider/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: navigate to edit profile
            },
            icon: Icon(Iconsax.edit_2, size: 22, color: colorScheme.onSurface),
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.profile == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.loading,
                strokeWidth: 2.5,
              ),
            );
          }

          final user = provider.profile;

          if (user == null) {
            return Center(
              child: Text(
                'Unable to load profile',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return AppBody(
            children: [
              // ── Avatar + Name ──────────────────────────────
              Center(
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: user.profile != null && user.profile!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                user.profile!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _AvatarFallback(name: user.fullname),
                              ),
                            )
                          : _AvatarFallback(name: user.fullname),
                    ),

                    const SizedBox(height: AppConst.spaceMD),

                    Text(
                      user.fullname,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConst.spaceXL),

              // ── Info Card ──────────────────────────────────
              _InfoCard(
                children: [
                  _InfoTile(
                    icon: Iconsax.sms,
                    label: 'Email',
                    value: user.email,
                  ),
                  _InfoTile(
                    icon: Iconsax.user,
                    label: 'Role',
                    value: user.role.toUpperCase(),
                  ),
                ],
              ),

              const SizedBox(height: AppConst.spaceXL),

              // ── Actions ────────────────────────────────────
              AppButton(
                'Edit Profile',
                icon: Iconsax.edit_2,
                variant: ButtonVariant.outline,
                onTap: () {
                  // TODO: navigate to edit
                },
              ),

              const SizedBox(height: AppConst.spaceMD),

              AppButton(
                'Logout',
                icon: Iconsax.logout,
                variant: ButtonVariant.filled,
                color: AppColors.error,
                onTap: () async {
                  final authProvider = context.read<AuthProvider>();
                  final profileProvider = context.read<ProfileProvider>();

                  await authProvider.logout();
                  if (!mounted) return;

                  await profileProvider.clearProfile();
                  if (context.mounted) {
                    context.go(Routes.login);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================
// Helpers
// ===========================================================

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConst.spaceMD,
        vertical: AppConst.spaceSM,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppConst.borderRadiusLG,
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppConst.spaceMD),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppConst.borderRadiusSM,
                ),
                child: Icon(icon, size: 18, color: colorScheme.primary),
              ),
              const SizedBox(width: AppConst.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
