import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

import '../../../core/widgets/auth/auth_widgets.dart';
import 'inserisci_codice_screen.dart';
import 'login_screen.dart';
import 'successo_nuova_password_screen.dart';

class NuovaPasswordScreen extends StatefulWidget {
  const NuovaPasswordScreen({
    super.key,
    this.email = '',
    this.code = '',
    this.onSave,
    this.onCancel,
  });

  final String email;
  final String code;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  State<NuovaPasswordScreen> createState() => _NuovaPasswordScreenState();
}

class _NuovaPasswordScreenState extends State<NuovaPasswordScreen> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _showPasswordError = false;
  String _passwordErrorMessage =
      'Le password inserite non\ncoincidono. Controlla i dati e\nriprova.';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthRecoveryScaffold(
      padding: AppSizes.pageHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.p14),
          AuthBackHeader(
            title: 'Verifica codice',
            onBack: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      InserisciCodiceScreen(email: widget.email),
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 250),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final tween = Tween<Offset>(
                          begin: const Offset(-1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.p35),
          const Center(
            child: AuthRecoveryBadge(icon: AuthRecoveryBadgeIcon.lock),
          ),
          const SizedBox(height: AppSizes.p42),
          const Text(
            'Imposta nuova password',
            style: AppTextStyles.strongTitle,
          ),
          const SizedBox(height: AppSizes.p10),
          const Text(
            'Scegli una nuova password per il tuo\naccount.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSizes.p32),
          if (_showPasswordError) ...[
            AuthErrorBanner(message: _passwordErrorMessage),
            const SizedBox(height: AppSizes.p28),
          ],
          AuthField(
            label: 'Nuova password',
            hint: '••••••••',
            obscureText: true,
            labelBottomSpacing: 0,
            controller: _passwordController,
            hasError: _showPasswordError,
          ),
          const SizedBox(height: AppSizes.p8),
          AuthField(
            label: 'Conferma nuova password',
            hint: '••••••••',
            obscureText: true,
            labelBottomSpacing: 0,
            controller: _confirmPasswordController,
            hasError: _showPasswordError,
          ),
          const SizedBox(height: AppSizes.p30),
          AuthPrimaryButton(
            text: 'Salva nuova password',
            onPressed: _isSaving ? null : _savePassword,
          ),
          const SizedBox(height: AppSizes.p17),
          AuthPrimaryButton(
            text: 'Annulla',
            onPressed: () {
              if (widget.onCancel != null) {
                widget.onCancel!();
              }
              Navigator.pushAndRemoveUntil(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 250),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final tween = Tween<Offset>(
                          begin: const Offset(-1, 0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (password.length < 10) {
      setState(() {
        _passwordErrorMessage =
            'La password deve contenere almeno 10 caratteri.';
        _showPasswordError = true;
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _passwordErrorMessage =
            'Le password inserite non\ncoincidono. Controlla i dati e\nriprova.';
        _showPasswordError = true;
      });
      return;
    }

    setState(() {
      _showPasswordError = false;
      _isSaving = true;
    });

    try {
      await ApiProvider.auth.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: password,
      );
      if (!mounted) {
        return;
      }

      if (widget.onSave != null) {
        widget.onSave!();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SuccessoNuovaPasswordScreen(),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _showPasswordError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
