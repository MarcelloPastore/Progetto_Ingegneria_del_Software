import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_client.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

import '../../../core/widgets/auth/auth_widgets.dart';
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
  bool _passwordTooShort = false;
  bool _passwordMismatch = false;
  bool _serverError = false;
  bool _isSubmitting = false;

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

  Future<void> _registrati() async {
    if (_isSubmitting) return;

    setState(() {
      _campiNonCompilati = false;
      _emailEsistente = false;
      _passwordTooShort = false;
      _passwordMismatch = false;
      _serverError = false;
    });

    final username = _usernameController.text.trim();
    final nome = _nomeController.text.trim();
    final cognome = _cognomeController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final invalidEmail = !RegExp(
      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$',
    ).hasMatch(email);
    final passwordTooShort =
        (password.isNotEmpty && password.length < 10) ||
        (confirmPassword.isNotEmpty && confirmPassword.length < 10);
    final passwordMismatch =
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password != confirmPassword;

    final invalidForm =
        username.length < 3 ||
        username.length > 50 ||
        nome.isEmpty ||
        nome.length > 100 ||
        cognome.isEmpty ||
        cognome.length > 100 ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        invalidEmail ||
        passwordTooShort ||
        passwordMismatch;

    if (invalidForm) {
      if (passwordTooShort) {
        setState(() => _passwordTooShort = true);
      } else if (passwordMismatch) {
        setState(() => _passwordMismatch = true);
      } else {
        setState(() => _campiNonCompilati = true);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiProvider.auth.register(
        username: username,
        nome: nome,
        cognome: cognome,
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => CheckEmailScreen(email: email)),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _emailEsistente = error.statusCode == 409;
        _campiNonCompilati = error.statusCode == 400;
        _serverError = error.statusCode != 400 && error.statusCode != 409;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _serverError = true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFieldError = _campiNonCompilati || _emailEsistente;
    final hasError =
        hasFieldError || _passwordTooShort || _passwordMismatch || _serverError;
    final passwordFieldError =
        hasFieldError || _passwordTooShort || _passwordMismatch;

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
                  ? "L’email inserita è già associata a un account esistente. "
                  : _serverError
                  ? "Registrazione temporaneamente non disponibile. Riprova tra poco."
                  : _passwordTooShort
                  ? "La password deve contenere almeno 10 caratteri."
                  : _passwordMismatch
                  ? "Le password non coincidono. Controlla e riprova."
                  : "Alcuni campi non sono stati compilati correttamente. Controlla i dati inseriti e riprova.",
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
            hasError: hasFieldError,
            passwordHasError: passwordFieldError,
            confirmPasswordHasError: passwordFieldError,
            obscurePassword: _obscurePassword,
            obscureConfirmPassword: _obscureConfirmPassword,
            usernameController: _usernameController,
            nomeController: _nomeController,
            cognomeController: _cognomeController,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            confirmPasswordErrorText: _passwordMismatch
                ? 'Le password non coincidono *'
                : null,
            onTogglePassword: () => setState(() {
              _obscurePassword = !_obscurePassword;
            }),
            onToggleConfirmPassword: () => setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            }),
          ),
          const SizedBox(height: AppSizes.p12),
          const Text(
            'La password deve contenere almeno 10 caratteri.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: AppSizes.p30),
          AuthPrimaryButton(
            text: _isSubmitting ? 'Registrazione...' : 'Registrati',
            compact: true,
            onPressed: _isSubmitting ? null : _registrati,
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
