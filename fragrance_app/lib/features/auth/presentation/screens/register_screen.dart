import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/constants/app_const.dart';
import '../../../../shared/shared.dart';
import '../../../profile/presentation/provider/profile_provider.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullname = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPassword = false;

  /// A problem found before asking the server (empty field, typo...).
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthProvider>().resetError(),
    );
  }

  @override
  void dispose() {
    _fullname.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Same rules as the backend, checked here so mistakes show at once.
  String? _validate() {
    final fullname = _fullname.text.trim();
    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (fullname.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      return 'Please fill in every field.';
    }
    if (!RegExp(r'^[A-Za-z0-9_.]{3,30}$').hasMatch(username)) {
      return 'Username must be 3 to 30 letters, numbers, dots or underscores.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'That email address does not look right.';
    }
    final strong =
        password.length >= 8 &&
        RegExp('[A-Za-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp('[^A-Za-z0-9]').hasMatch(password);
    if (!strong) {
      return 'Password needs at least 8 characters, '
          'with a letter, a number and a symbol.';
    }
    if (password != _confirm.text) {
      return 'The two passwords do not match.';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    final problem = _validate();
    setState(() => _formError = problem);
    if (problem != null) return;

    final auth = context.read<AuthProvider>();
    await auth.register(
      fullname: _fullname.text,
      username: _username.text,
      email: _email.text,
      password: _password.text,
    );
    await _goHomeIfSignedIn(auth);
  }

  Future<void> _handleGoogle() async {
    setState(() => _formError = null);
    final auth = context.read<AuthProvider>();
    await auth.loginWithGoogle();
    await _goHomeIfSignedIn(auth);
  }

  Future<void> _goHomeIfSignedIn(AuthProvider auth) async {
    if (!mounted || !auth.isAuthenticated) return;

    await context.read<ProfileProvider>().getProfile();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Welcome! Your account is ready.')),
    );
    context.go(Routes.main);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final auth = context.watch<AuthProvider>();
    final error = _formError ?? auth.error;

    final eye = IconButton(
      onPressed: () => setState(() => _showPassword = !_showPassword),
      icon: Icon(_showPassword ? Iconsax.eye_slash : Iconsax.eye, size: 20),
    );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppConst.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.user_add,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppConst.spaceMD),
                Text(
                  'Create account',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConst.spaceXS),
                Text(
                  'Join us to save your cart and place orders',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConst.spaceXL),

                // ── Fields ──
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
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Iconsax.sms, size: 20),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppConst.spaceMD),
                AppTextfield(
                  controller: _password,
                  labelText: 'Password',
                  prefixIcon: const Icon(Iconsax.lock, size: 20),
                  suffixIcon: eye,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppConst.spaceXS),
                Text(
                  'At least 8 characters with a letter, a number and a symbol.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppConst.spaceMD),
                AppTextfield(
                  controller: _confirm,
                  labelText: 'Confirm password',
                  prefixIcon: const Icon(Iconsax.lock_1, size: 20),
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                ),

                // ── Error ──
                if (error != null) ...[
                  const SizedBox(height: AppConst.spaceMD),
                  Text(
                    error,
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: AppConst.spaceLG),

                // ── Buttons ──
                AppButton(
                  'Create account',
                  isLoading: auth.isLoading,
                  onTap: auth.isLoading ? null : _handleRegister,
                ),

                if (!kIsWeb) ...[
                  const SizedBox(height: AppConst.spaceMD),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConst.spaceSM,
                        ),
                        child: Text(
                          'or',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppConst.spaceMD),
                  AppButton(
                    'Sign up with Google',
                    icon: Icons.g_mobiledata_rounded,
                    variant: ButtonVariant.outline,
                    onTap: auth.isLoading ? null : _handleGoogle,
                  ),
                ],

                const SizedBox(height: AppConst.spaceXL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: textTheme.labelMedium,
                    ),
                    TextButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(Routes.login),
                      child: const Text('Log in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
