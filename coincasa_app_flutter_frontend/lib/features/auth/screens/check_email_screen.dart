import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/auth/screens/login_screen.dart';

class CheckEmailScreen extends StatelessWidget {
  final String email;

  const CheckEmailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = email.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: AppSizes.page,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brandAccent,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'email controllata',
                              style: AppTextStyles.link,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.p60),

                        SvgPicture.asset(
                          'assets/Icons/check_email.svg',
                          width: AppSizes.p100,
                          height: AppSizes.p100,
                          placeholderBuilder: (context) => const SizedBox(
                            width: AppSizes.p100,
                            height: AppSizes.p100,
                          ),
                        ),

                        const SizedBox(height: AppSizes.p32),

                        const Text(
                          'Controlla la tua mail!',
                          style: AppTextStyles.screenTitle,
                        ),

                        const SizedBox(height: AppSizes.p16),

                        const Text(
                          'Abbiamo inviato un link di verifica a:',
                          style: AppTextStyles.bodyMuted,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppSizes.p24),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.p20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            border: Border.all(
                              color: AppColors.brandAccent,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius16,
                            ),
                          ),
                          child: Text(
                            normalizedEmail,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.brandAccent,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: AppSizes.p48),

                        const Text(
                          "Clicca sul link nell'email per\nattivare il tuo account.\nPotrebbe richiedere qualche\nminuto.",
                          style: AppTextStyles.bodyMutedRelaxed,
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(),

                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodyMuted,
                            children: [
                              const TextSpan(
                                text: "Non hai ricevuto l'email? ",
                              ),
                              TextSpan(
                                text: 'Reinvia',
                                style: AppTextStyles.link.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Logica di reinvio email
                                  },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSizes.p24),

                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodyMuted,
                            children: [
                              const TextSpan(text: "Email sbagliata? "),
                              TextSpan(
                                text: 'Modifica',
                                style: AppTextStyles.link.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pop(context);
                                  },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSizes.p20),
                        const AuthPageDots(activeIndex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
