import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/validation_utils.dart';
import 'package:coincasa_app/core/widgets/auth/auth_widgets.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/ui/casa/screens/casa_welcome_screen.dart';
import 'package:coincasa_app/ui/dashboard/screens/dashboard_screen.dart';

import 'password_dimenticata.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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

    if (!ValidationUtils.isValidEmail(email) || password.isEmpty) {
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
      await ref.read(authViewModelProvider.notifier).login(email, password);
      
      final authState = ref.read(authViewModelProvider);
      if (authState.hasError) {
        throw authState.error!;
      }

      final user = authState.value;
      if (user == null) throw Exception('Login failed');

      // Verifica se l'utente ha almeno una casa
      List<Casa> caseUtente = [];
      try {
        caseUtente = await ref.read(listaCaseViewModelProvider.future);
      } catch (_) {
        // In caso di errore, naviga alla Dashboard come fallback
      }

      if (!mounted) return;

      if (caseUtente.isNotEmpty) {
        // Forza sempre la selezione della prima casa disponibile per garantire
        // un JWT con il contesto casa valido, indipendentemente dallo stato precedente.
        try {
          final firstCasaId = caseUtente.first.id;
          final ruolo = await ref.read(listaCaseViewModelProvider.notifier).selectCasa(firstCasaId);
          if (mounted) {
            ActiveCasaScope.read(context).setCasaContext(
              casaId: firstCasaId,
              ruolo: ruolo,
            );
          }
        } catch (_) {
          // La dashboard gestirà la selezione come fallback.
        }
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
              userId: user.id,
              username: user.username,
              firstName: user.nome,
              lastName: user.cognome,
              displayName: user.displayName,
            ),
          ),
        );
      }
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
