import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

import '../../../core/widgets/auth/auth_widgets.dart';
import 'login_screen.dart';

class SuccessoNuovaPasswordScreen extends StatelessWidget {
  const SuccessoNuovaPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthRecoveryScaffold(
      padding: AppSizes.pageHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSizes.p60),
          const Icon(
            Icons.check_rounded,
            color: AppColors.successBright,
            size: 92,
          ),
          const SizedBox(height: AppSizes.p24),
          const Text(
            'Nuova password salvata!',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p12),
          const Text(
            'La tua password è stata\naggiornata con successo. Ora\npuoi tornare alla schermata di\nLogin',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p56),
          AuthPrimaryButton(
            text: 'Torna al Login',
            onPressed: () {
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
}
