import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_const.dart';
import '../../../../shared/shared.dart';
import '../../../profile/presentation/provider/profile_provider.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    await authProvider.login(email: email.text.trim(), password: password.text);

    if (!context.mounted) return;

    if (authProvider.isAuthenticated) {
      await context.read<ProfileProvider>().getProfile();

      if (!context.mounted) return;

      context.go(Routes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppConst.paddingScreen,
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─────────────────────────────
                    // Header
                    // ─────────────────────────────
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.security,
                            size: 36,
                            color: colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: AppConst.spaceMD),

                        Text(
                          'Login',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppConst.spaceXS),

                        Text(
                          'Enter your credentials to access your account',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConst.spaceXL),

                    // ─────────────────────────────
                    // Email
                    // ─────────────────────────────
                    AppTextfield(
                      controller: email,
                      hintText: 'example@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: AppConst.spaceMD),

                    // ─────────────────────────────
                    // Password
                    // ─────────────────────────────
                    AppTextfield(
                      controller: password,
                      hintText: '********',
                      obscureText: true,
                    ),

                    // ─────────────────────────────
                    // Forgot Password
                    // ─────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Forgot password
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ),

                    // ─────────────────────────────
                    // Error
                    // ─────────────────────────────
                    if (auth.error != null) ...[
                      const SizedBox(height: AppConst.spaceSM),
                      Text(
                        auth.error!,
                        style: TextStyle(color: colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: AppConst.spaceLG),

                    // ─────────────────────────────
                    // Login Button
                    // ─────────────────────────────
                    if (auth.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      AppButton('Login', onTap: () => _handleLogin(context)),

                    const SizedBox(height: AppConst.spaceSM),

                    // ─────────────────────────────
                    // Guest Login
                    // ─────────────────────────────
                    AppButton(
                      'Continue as Guest',
                      onTap: () => context.go(Routes.main),
                      variant: ButtonVariant.text,
                    ),

                    // ─────────────────────────────
                    // Register
                    // ─────────────────────────────
                    const SizedBox(height: AppConst.spaceXL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: textTheme.labelMedium,
                        ),
                        TextButton(
                          onPressed: () async =>
                              await context.push(Routes.register),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
