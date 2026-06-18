import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

import '../../../core/widgets/auth/auth_widgets.dart';
import '../../../core/widgets/common/common_widgets.dart';
import 'attesa_invio_codice_screen.dart';
import 'login_screen.dart';
import 'nuova_password_screen.dart';

class ErroreCodiceNonCorrettoScreen extends StatefulWidget {
  const ErroreCodiceNonCorrettoScreen({
    super.key,
    this.email = 'marco@gmail.com',
    this.onVerify,
    this.onCancel,
    this.onResend,
  });

  final String email;
  final VoidCallback? onVerify;
  final VoidCallback? onCancel;
  final VoidCallback? onResend;

  @override
  State<ErroreCodiceNonCorrettoScreen> createState() =>
      _ErroreCodiceNonCorrettoScreenState();
}

class _ErroreCodiceNonCorrettoScreenState
    extends State<ErroreCodiceNonCorrettoScreen> {
  late final TextEditingController _codeController;
  late final FocusNode _codeFocusNode;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _codeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = widget.email.trim().toLowerCase();

    return AuthRecoveryScaffold(
      padding: AppSizes.compactPage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.p14),
          const AuthBackHeader(title: 'Recupero password'),
          const SizedBox(height: AppSizes.p30),
          const Center(
            child: AuthRecoveryBadge(icon: AuthRecoveryBadgeIcon.email),
          ),
          const SizedBox(height: AppSizes.p20),
          const Padding(
            padding: EdgeInsets.only(left: AppSizes.p14),
            child: Text('Controlla la tua email', style: AppTextStyles.title),
          ),
          const SizedBox(height: AppSizes.p4),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.p14),
            child: Text(
              'Abbiamo inviato un codice a\n$normalizedEmail inseriscilo qui\nsotto.',
              style: AppTextStyles.body.copyWith(height: 1.05),
            ),
          ),
          const SizedBox(height: AppSizes.p25),
          const AuthErrorBanner(
            message:
                'Il codice inserito non è corretto o è scaduto. Riprova o richiedi un nuovo codice.',
          ),
          const SizedBox(height: AppSizes.p20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p10),
            child: Text(
              'Codice di verifica',
              style: AppTextStyles.recoveryLabel,
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AppOtpInput(
              controller: _codeController,
              focusNode: _codeFocusNode,
              hasError: true,
            ),
          ),
          const SizedBox(height: AppSizes.p23),
          Center(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.body.copyWith(height: 1),
                children: [
                  const TextSpan(text: 'Non hai ricevuto il codice ? '),
                  TextSpan(
                    text: 'Reinvia',
                    style: AppTextStyles.link,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        if (widget.onResend != null) {
                          widget.onResend!();
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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AuthPrimaryButton(
              text: 'Verifica codice',
              onPressed: () {
                final code = _codeController.text.trim();
                if (code.length != 6) {
                  return;
                }

                if (widget.onVerify != null) {
                  widget.onVerify!();
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NuovaPasswordScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.p17),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AuthPrimaryButton(
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
                    reverseTransitionDuration: const Duration(
                      milliseconds: 250,
                    ),
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
          ),
        ],
      ),
    );
  }
}
