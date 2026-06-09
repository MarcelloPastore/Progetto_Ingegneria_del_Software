import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

import 'check_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _campiNonCompilati = false;
  bool _emailEsistente = false;

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _nomeController.dispose();
    _cognomeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _registrati() {
    setState(() {
      _campiNonCompilati = false;
      _emailEsistente = false;
    });

    final username = _usernameController.text.trim();
    final nome = _nomeController.text.trim();
    final cognome = _cognomeController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final invalidEmail =
        !email.contains('@') ||
        !(email.endsWith('.com') || email.endsWith('.it'));
    final invalidForm =
        username.isEmpty ||
        nome.isEmpty ||
        cognome.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        invalidEmail ||
        password != confirmPassword;

    if (invalidForm) {
      setState(() => _campiNonCompilati = true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckEmailScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _campiNonCompilati || _emailEsistente;

    return AuthRecoveryScaffold(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p32,
        vertical: AppSizes.p0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crea il tuo account', style: AppTextStyles.screenTitle),
          if (hasError) ...[
            const SizedBox(height: AppSizes.p16),
            AuthErrorBanner(
              compact: true,
              message: _emailEsistente
                  ? "L'email inserita è gia associata a un account esistente. "
                  : 'Alcuni campi non sono stati compilati correttamente. Controlla i dati inseriti e riprova.',
              actionText: _emailEsistente ? 'Accedi' : null,
              trailingMessage: _emailEsistente
                  ? " oppure utilizza un'altra email."
                  : null,
              onAction: _emailEsistente
                  ? () => Navigator.pop(
                      context,
                      _emailController.text.trim().toLowerCase(),
                    )
                  : null,
            ),
            const SizedBox(height: AppSizes.p20),
          ] else
            const SizedBox(height: AppSizes.p12),
          AuthRegisterFields(
            hasError: hasError,
            obscurePassword: _obscurePassword,
            obscureConfirmPassword: _obscureConfirmPassword,
            usernameController: _usernameController,
            nomeController: _nomeController,
            cognomeController: _cognomeController,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            onTogglePassword: () => setState(() {
              _obscurePassword = !_obscurePassword;
            }),
            onToggleConfirmPassword: () => setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            }),
          ),
          const SizedBox(height: AppSizes.p30),
          AuthPrimaryButton(
            text: 'Registrati',
            compact: true,
            onPressed: _registrati,
          ),
          const SizedBox(height: AppSizes.p20),
          const AuthDivider(),
          const SizedBox(height: AppSizes.p3),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(
                context,
                _emailController.text.trim().toLowerCase(),
              ),
              child: const Text.rich(
                TextSpan(
                  style: AppTextStyles.link,
                  children: [
                    TextSpan(text: 'Hai già un account? '),
                    TextSpan(text: 'Accedi', style: AppTextStyles.linkStrong),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p2),
          const AuthPageDots(activeIndex: 0),
        ],
      ),
    );
  }
}
