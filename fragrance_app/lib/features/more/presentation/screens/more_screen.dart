import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/providers/theme_provider.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/core.dart';
import '../../../../shared/shared.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../../../profile/presentation/provider/profile_provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeText = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        // title: const Text('More')
      ),
      body: AppBody(
        children: [
          // 1. Profile Preview
          AuthPreferences.isAuthenticated
              ? const _ProfileCard()
              : Container(
                  padding: const EdgeInsets.all(AppConst.spaceMD),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppConst.radiusLG),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sync Your Scents',
                                  style: themeText.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppConst.spaceXS),
                                Text(
                                  'Sign in to access your tailored dashboard, track orders, and personalize your routine.',
                                  style: themeText.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppConst.spaceSM),
                          // Right: Iconsax User Security / Profile Icon
                          Container(
                            padding: const EdgeInsets.all(AppConst.spaceSM),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.user_octagon,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConst.spaceLG),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          'Claim Your Membership',
                          icon: Iconsax.star_1,
                          variant: ButtonVariant.filled,
                          onTap: () async => context.go(Routes.login),
                        ),
                      ),
                    ],
                  ),
                ),

          const SizedBox(height: AppConst.spaceXL),

          // 2. Quick Actions
          AppSection(
            title: 'My Activity',
            padding: const EdgeInsets.all(AppConst.spaceMD),
            spacing: AppConst.spaceMD,
            children: [
              _QuickActionsGrid(
                items: [
                  _ActionItem(
                    icon: Iconsax.truck,
                    label: 'Shipping',
                    onTap: () {},
                  ),
                  _ActionItem(
                    icon: Iconsax.star_1,
                    label: 'Reviews',
                    onTap: () {},
                  ),
                  _ActionItem(
                    icon: Iconsax.clock,
                    label: 'History',
                    onTap: () => context.push(Routes.orders),
                  ),
                  _ActionItem(
                    icon: Iconsax.heart,
                    label: 'Favorites',
                    onTap: () {
                      // context.push(Routes.favorite);
                    },
                  ),
                  _ActionItem(
                    icon: Iconsax.bag_2,
                    label: 'Orders',
                    onTap: () => context.push(Routes.orders),
                  ),
                  _ActionItem(
                    icon: Iconsax.location,
                    label: 'Address',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppConst.spaceXL),

          // 3. Wallet
          AppSection(
            title: 'Wallet',
            padding: const EdgeInsets.all(AppConst.spaceMD),
            children: [
              _WalletTile(
                balance: context.watch<ProfileProvider>().walletBalance,
                onTopUp: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Top-ups are added by the shop for now. '
                        'You can also pay with ABA PayWay at checkout.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppConst.spaceXL),

          // 4. Appearance
          AppSection(
            title: 'Appearance',
            padding: const EdgeInsets.symmetric(
              horizontal: AppConst.spaceMD,
              vertical: AppConst.spaceSM,
            ),
            children: [
              _AppearanceTile(
                onChanged: (isDark) async =>
                    await context.read<ThemeProvider>().toggleTheme(),
              ),
            ],
          ),

          const SizedBox(height: AppConst.spaceXL),

          // 5. Logout
          if (AuthPreferences.isAuthenticated)
            AppButton(
              'Log Out',
              icon: Iconsax.logout,
              variant: ButtonVariant.outline,
              color: colorScheme.error,
              textColor: colorScheme.error,
              onTap: () async {
                await context.read<AuthProvider>().logout();
              },
            ),
        ],
      ),
    );
  }
}

// ===========================================================
// Profile Card
// ===========================================================
/// Round profile photo, or the first letter of the name when there is none.
class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
    return CircleAvatar(
      radius: 28,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      child: imageUrl == null || imageUrl!.isEmpty
          ? initial
          : AppImage(
              image: imageUrl,
              variant: ImageVariant.avatar,
              width: 56,
              height: 56,
              errorBuilder: (_, _, _) => Center(child: initial),
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: AppConst.borderRadiusLG,
      child: InkWell(
        onTap: () => context.push(Routes.profile),
        borderRadius: AppConst.borderRadiusLG,
        child: Padding(
          padding: const EdgeInsets.all(AppConst.spaceMD),
          child: Row(
            children: [
              _MiniAvatar(
                imageUrl: profile?.profile,
                name: profile?.fullname ?? '',
              ),
              const SizedBox(width: AppConst.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullname ??
                          (profileProvider.isLoading
                              ? 'Loading…'
                              : 'Tap to load your profile'),
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile == null ? '' : '@${profile.username} · ${profile.email}',
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// Quick Actions Grid
// ===========================================================
class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.items});

  final List<_ActionItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppConst.spaceMD,
        crossAxisSpacing: AppConst.spaceMD,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        return _ActionTile(item: items[index]);
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.item});

  final _ActionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: AppConst.borderRadiusMD,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: AppConst.borderRadiusMD,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: AppConst.borderRadiusSM,
              ),
              child: Icon(item.icon, size: 22, color: colorScheme.primary),
            ),
            const SizedBox(height: AppConst.spaceSM),
            Text(
              item.label,
              style: textTheme.labelMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// Wallet Tile
// ===========================================================
class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.balance, required this.onTopUp});

  /// Null when signed out or not loaded yet.
  final double? balance;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: AppConst.borderRadiusMD,
          ),
          child: Icon(Iconsax.wallet_3, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(width: AppConst.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Balance', style: textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                balance == null
                    ? (AuthPreferences.isAuthenticated ? '…' : 'Sign in to see')
                    : '\$${balance!.toStringAsFixed(2)}',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        AppButton(
          'Top Up',
          width: 100,
          height: 40,
          variant: ButtonVariant.filled,
          onTap: onTopUp,
        ),
      ],
    );
  }
}

// ===========================================================
// Appearance Tile
// ===========================================================
class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: AppConst.borderRadiusSM,
          ),
          child: Icon(
            isDark ? Iconsax.moon : Iconsax.sun_1,
            size: 22,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppConst.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: textTheme.titleSmall),
              Text(
                isDark ? 'Dark mode' : 'Light mode',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch.adaptive(value: isDark, onChanged: onChanged),
      ],
    );
  }
}
