import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_client.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/services/session_manager.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/auth/auth_widgets.dart';
import 'package:coincasa_app/features/casa/screens/casa_welcome_screen.dart';
import 'package:coincasa_app/features/dashboard/screens/dashboard_screen.dart';

import 'password_dimenticata.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _hasLoginError = false;
  bool _isLoggingIn = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_hasLoginError) {
      setState(() {
        _hasLoginError = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoggingIn) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Simple email validation using RegExp
    final bool emailValid = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
    final bool passwordValid = password.isNotEmpty;

    if (!emailValid || !passwordValid) {
      setState(() {
        _hasLoginError = true;
      });
      return;
    }

    setState(() {
      _hasLoginError = false;
      _isLoggingIn = true;
    });

    try {
      final loginResult = await ApiProvider.auth.login(
        email: email,
        password: password,
      );

      ApiProvider.client.setAuthToken(loginResult.token);
      ApiProvider.client.setCurrentUserIdentity(
        id: loginResult.user.id,
        email: email,
        name: loginResult.user.nome,
        surname: loginResult.user.cognome,
        displayName: loginResult.user.displayName,
        username: loginResult.user.username,
      );
      await SessionManager.save(
        token: loginResult.token,
        userId: loginResult.user.id,
        email: email,
        username: loginResult.user.username,
        nome: loginResult.user.nome,
        cognome: loginResult.user.cognome,
      );

      // Verifica se l'utente ha almeno una casa
      List<Casa> caseUtente = [];
      try {
        caseUtente = await ApiProvider.casa.list();
      } catch (_) {
        // In caso di errore, naviga alla Dashboard come fallback
      }

      if (!mounted) return;

      if (caseUtente.isNotEmpty) {
        final prima = caseUtente.first;
        try {
          final ruolo = await SessionManager.selectCasa(casaId: prima.id);
          if (mounted) {
            ActiveCasaScope.read(context)
                .setCasaContext(casaId: prima.id, ruolo: ruolo);
          }
        } catch (_) {}
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CasaWelcomeScreen(
              email: email,
              userId: loginResult.user.id,
              username: loginResult.user.username,
              firstName: loginResult.user.nome,
              lastName: loginResult.user.cognome,
              displayName: loginResult.user.displayName,
            ),
          ),
        );
      }
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _hasLoginError = true;
        _isLoggingIn = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasLoginError = true;
        _isLoggingIn = false;
      });
    }
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
            controller: _passwordController,
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
          AuthPrimaryButton(
            text: _isLoggingIn ? 'Accesso...' : 'Accedi',
            compact: true,
            onPressed: _isLoggingIn ? null : _login,
          ),
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
