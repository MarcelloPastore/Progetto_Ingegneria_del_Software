import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

import '../../../core/widgets/auth/auth_widgets.dart';
import 'attesa_invio_codice_screen.dart';

class ErroreEmailNonRiconosciutaScreen extends StatefulWidget {
  const ErroreEmailNonRiconosciutaScreen({
    super.key,
    this.email = '',
    this.onSendCode,
    this.onCancel,
  });

  final String email;
  final VoidCallback? onSendCode;
  final VoidCallback? onCancel;

  @override
  State<ErroreEmailNonRiconosciutaScreen> createState() =>
      _ErroreEmailNonRiconosciutaScreenState();
}

class _ErroreEmailNonRiconosciutaScreenState
    extends State<ErroreEmailNonRiconosciutaScreen> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: _normalizeEmail(widget.email),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = _normalizeEmail(widget.email);

    return AuthRecoveryScaffold(
      padding: AppSizes.compactPage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.p60),
          const Center(
            child: AuthRecoveryBadge(icon: AuthRecoveryBadgeIcon.key),
          ),
          const SizedBox(height: AppSizes.p37),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p12),
            child: Text('Password dimenticata?', style: AppTextStyles.title),
          ),
          const SizedBox(height: AppSizes.p10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p12),
            child: Text(
              'Inserisci la tua email e ti invieremo\nun codice per reimpostare la password.',
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: AppSizes.p21),
          const AuthErrorBanner(
            message:
                "Email non riconosciuta. Controlla di aver inserito l'indirizzo corretto.",
          ),
          const SizedBox(height: AppSizes.p27),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AuthField(
              label: 'Email',
              hint: normalizedEmail,
              controller: _emailController,
              hasError: true,
            ),
          ),
          const SizedBox(height: AppSizes.p39),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AuthPrimaryButton(
              text: 'Invia codice',
              onPressed: () {
                final normalizedInput = _normalizeEmail(_emailController.text);
                if (!_isValidEmail(normalizedInput)) {
                  return;
                }

                if (widget.onSendCode != null) {
                  widget.onSendCode!();
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AttesaInvioCodiceScreen(email: normalizedInput),
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
              onPressed: widget.onCancel ?? () => Navigator.maybePop(context),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidEmail(String email) {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || !normalized.contains('@')) {
      return false;
    }

    return normalized.endsWith('.com') || normalized.endsWith('.it');
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}
