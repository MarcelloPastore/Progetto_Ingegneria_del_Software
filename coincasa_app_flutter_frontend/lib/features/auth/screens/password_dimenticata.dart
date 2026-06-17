import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

import '../../../core/widgets/auth/auth_widgets.dart';
import 'attesa_invio_codice_screen.dart';
import 'login_screen.dart';

class PasswordDimenticataScreen extends StatefulWidget {
  const PasswordDimenticataScreen({
    super.key,
    this.email = '',
    this.onSendCode,
    this.onCancel,
  });

  final String email;
  final VoidCallback? onSendCode;
  final VoidCallback? onCancel;

  @override
  State<PasswordDimenticataScreen> createState() =>
      _PasswordDimenticataScreenState();
}

class _PasswordDimenticataScreenState extends State<PasswordDimenticataScreen> {
  late final TextEditingController _emailController;
  bool _showEmailError = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedHintEmail = _normalizeEmail(widget.email);

    return AuthRecoveryScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.p60),
          const Center(
            child: AuthRecoveryBadge(icon: AuthRecoveryBadgeIcon.key),
          ),
          const SizedBox(height: AppSizes.p37),
          const Text('Password dimenticata?', style: AppTextStyles.title),
          const SizedBox(height: AppSizes.p10),
          const Text(
            'Inserisci la tua email e ti invieremo\nun codice per reimpostare la\npassword.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSizes.p21),
          if (_showEmailError) ...[
            const AuthErrorBanner(
              message:
                  "Email non riconosciuta. Controlla di aver inserito l'indirizzo corretto.",
            ),
            const SizedBox(height: AppSizes.p27),
          ],
          AuthField(
            label: 'Email',
            hint: normalizedHintEmail,
            controller: _emailController,
            hasError: _showEmailError,
          ),
          const SizedBox(height: AppSizes.p38),
          AuthPrimaryButton(
            text: 'Invia codice',
            onPressed: () {
              final normalizedEmail = _normalizeEmail(_emailController.text);
              if (!_isValidEmail(normalizedEmail)) {
                setState(() {
                  _showEmailError = true;
                });
                return;
              }

              if (_showEmailError) {
                setState(() {
                  _showEmailError = false;
                });
              }

              if (widget.onSendCode != null) {
                widget.onSendCode!();
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AttesaInvioCodiceScreen(email: normalizedEmail),
                ),
              );
            },
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

  bool _isValidEmail(String email) {
    final normalized = _normalizeEmail(email);
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}
