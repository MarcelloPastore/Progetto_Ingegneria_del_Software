import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

import 'inserisci_codice_screen.dart';

class ErrorePasswordNonValideScreen extends StatelessWidget {
  const ErrorePasswordNonValideScreen({super.key, this.onSave, this.onCancel});

  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AuthRecoveryScaffold(
      padding: AppSizes.compactPage,
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
                      const InserisciCodiceScreen(),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: Text(
              'Imposta nuova password',
              style: AppTextStyles.strongTitle,
            ),
          ),
          const SizedBox(height: AppSizes.p10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: Text(
              'Scegli una nuova password per il tuo\naccount.',
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: AppSizes.p27),
          const AuthErrorBanner(
            message:
                'Le password inserite non\ncoincidono. Controlla i dati e\nriprova.',
          ),
          const SizedBox(height: AppSizes.p28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AuthField(
              label: 'Nuova password',
              hint: '••••••••',
              obscureText: true,
              hasError: true,
              labelBottomSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AuthField(
              label: 'Conferma nuova password',
              hint: '••••••',
              obscureText: true,
              hasError: true,
              labelBottomSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSizes.p30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AuthPrimaryButton(
              text: 'Salva nuova password',
              onPressed: onSave,
            ),
          ),
          const SizedBox(height: AppSizes.p17),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: AuthPrimaryButton(
              text: 'Annulla',
              onPressed: onCancel ?? () => Navigator.maybePop(context),
            ),
          ),
        ],
      ),
    );
  }
}
