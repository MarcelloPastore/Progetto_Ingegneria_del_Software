import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

import 'attesa_invio_codice_screen.dart';
import 'login_screen.dart';
import 'nuova_password_screen.dart';
import 'password_dimenticata.dart';

class InserisciCodiceScreen extends StatefulWidget {
  const InserisciCodiceScreen({
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
  State<InserisciCodiceScreen> createState() => _InserisciCodiceScreenState();
}

class _InserisciCodiceScreenState extends State<InserisciCodiceScreen> {
  late final TextEditingController _codeController;
  late final FocusNode _codeFocusNode;
  bool _showCodeError = false;
  bool _isVerifying = false;

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
    final codeBorderColor = _showCodeError
        ? AppColors.error
        : AppColors.inputBorderDark;

    return AuthRecoveryScaffold(
      padding: AppSizes.pageHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.p14),
          AuthBackHeader(
            title: 'Recupero password',
            onBack: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PasswordDimenticataScreen(email: normalizedEmail),
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.p30),
          const Center(
            child: AuthRecoveryBadge(icon: AuthRecoveryBadgeIcon.email),
          ),
          const SizedBox(height: AppSizes.p20),
          const Padding(
            padding: EdgeInsets.only(left: AppSizes.p5),
            child: Text('Controlla la tua email', style: AppTextStyles.title),
          ),
          const SizedBox(height: AppSizes.p4),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.p5),
            child: Text(
              'Abbiamo inviato un codice a\n$normalizedEmail inseriscilo qui\nsotto.',
              style: AppTextStyles.body.copyWith(height: 1.05),
            ),
          ),
          const SizedBox(height: AppSizes.p25),
          if (_showCodeError) ...[
            const AuthErrorBanner(
              message:
                  'Il codice inserito non è corretto o è scaduto. Riprova o richiedi un nuovo codice.',
            ),
            const SizedBox(height: AppSizes.p20),
          ],
          const Text('Codice di verifica', style: AppTextStyles.recoveryLabel),
          const SizedBox(height: AppSizes.p4),
          Container(
            width: double.infinity,
            height: 102,
            decoration: BoxDecoration(
              color: AppColors.inputFillDark,
              border: Border.all(color: codeBorderColor, width: 2),
              borderRadius: BorderRadius.circular(AppSizes.radius15),
            ),
            child: Center(
              child: TextField(
                controller: _codeController,
                focusNode: _codeFocusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                style: AppTextStyles.input.copyWith(
                  fontSize: 34,
                  letterSpacing: AppSizes.p24,
                ),
                cursorColor: AppColors.focus,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  counterText: '',
                  isCollapsed: true,
                ),
              ),
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
          AuthPrimaryButton(
            text: 'Verifica codice',
            onPressed: _isVerifying ? null : () => _verify(normalizedEmail),
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

  Future<void> _verify(String email) async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _showCodeError = true;
      });
      return;
    }

    setState(() {
      _showCodeError = false;
      _isVerifying = true;
    });

    try {
      await ApiProvider.auth.verifyPasswordResetCode(email: email, code: code);
      if (!mounted) {
        return;
      }

      if (widget.onVerify != null) {
        widget.onVerify!();
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NuovaPasswordScreen(email: email, code: code),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _showCodeError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }
}
