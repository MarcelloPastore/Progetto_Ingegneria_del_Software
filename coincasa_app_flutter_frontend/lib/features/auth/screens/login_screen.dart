import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/auth/auth_widgets.dart';

import 'password_dimenticata.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final bool _hasLoginError = false;
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _hasLoginError;

    return AuthRecoveryScaffold(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p30,
        vertical: AppSizes.p28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AuthLoginLogo(),
          const SizedBox(height: AppSizes.p12),
          const Text('CoinCasa', style: AppTextStyles.brandTitle),
          const SizedBox(height: AppSizes.p15),
          const Text('Bentornato!', style: AppTextStyles.subtitle),
          if (hasError) ...[
            const SizedBox(height: AppSizes.p16),
            const AuthErrorBanner(
              compact: true,
              message:
                  'Email o password non corretti.\nControlla i dati inseriti e riprova.',
            ),
            const SizedBox(height: AppSizes.p20),
          ] else ...[
            const SizedBox(height: AppSizes.p4),
            const Text(
              'Gestisci la convivenza senza stress',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSizes.p20),
          ],
          AuthField(
            label: 'Email',
            hint: 'marco@gmail.com',
            controller: _emailController,
            hasError: hasError,
            height: AppSizes.p58,
            labelBottomSpacing: AppSizes.p8,
            recoveryStyle: false,
            contentPadding: AppSizes.inputContentTall,
          ),
          const SizedBox(height: AppSizes.p20),
          AuthField(
            label: 'Password',
            hint: '••••••••',
            obscureText: _obscurePassword,
            hasError: hasError,
            height: AppSizes.p58,
            labelBottomSpacing: AppSizes.p8,
            recoveryStyle: false,
            contentPadding: AppSizes.inputContentTall,
            suffixIcon: AuthPasswordToggle(
              obscured: _obscurePassword,
              onTap: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
            ),
          ),
          const SizedBox(height: AppSizes.p29),
          GestureDetector(
            onTap: () => _openPasswordRecovery(context),
            child: const Text(
              'Password dimenticata?',
              style: AppTextStyles.link,
            ),
          ),
          const SizedBox(height: AppSizes.p29),
          const AuthPrimaryButton(text: 'Accedi', compact: true),
          const SizedBox(height: AppSizes.p25),
          const AuthDivider(),
          const SizedBox(height: AppSizes.p20),
          TextButton(
            onPressed: () => _openRegister(context),
            child: const Text.rich(
              TextSpan(
                style: AppTextStyles.link,
                children: [
                  TextSpan(text: 'Non hai un account?  '),
                  TextSpan(text: 'Registrati', style: AppTextStyles.linkStrong),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPasswordRecovery(BuildContext context) {
    final normalizedEmail = _emailController.text.trim().toLowerCase();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PasswordDimenticataScreen(
          email: normalizedEmail.isEmpty ? 'marco@gmail.com' : normalizedEmail,
        ),
      ),
    );
  }

  Future<void> _openRegister(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _emailController.text = result.trim().toLowerCase();
      });
    }
  }
}
