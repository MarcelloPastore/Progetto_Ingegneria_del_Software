import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class AccountActivatedScreen extends StatelessWidget {
  const AccountActivatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p32,
                    vertical: AppSizes.p32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.18),
                      Image.asset(
                        'assets/Icons/green_check_mark.png',
                        width: AppSizes.p100,
                        height: AppSizes.p100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSizes.p58),
                      const Text(
                        'Account attivato!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenTitleStrong,
                      ),
                      const SizedBox(height: AppSizes.p32),
                      const Text(
                        'La tua email è stata verificata\ncon successo. Ora puoi\ncontinuare e creare la tua casa\ncondivisa.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMutedLarge,
                      ),
                      const SizedBox(height: AppSizes.p48),
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.p60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: AppColors.textOnDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius16,
                              ),
                              side: const BorderSide(
                                color: AppColors.primaryBorder,
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Continua',
                            style: AppTextStyles.button,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.p20),
                      const AuthPageDots(activeIndex: 2),
                    ],
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
