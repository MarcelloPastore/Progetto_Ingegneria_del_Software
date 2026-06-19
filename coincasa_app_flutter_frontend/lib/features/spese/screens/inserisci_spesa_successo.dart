import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_membro.dart';

class InserisciSpesaSuccessoArgs {
  const InserisciSpesaSuccessoArgs({this.memberFlow = false});

  final bool memberFlow;
}

class InserisciSpesaSuccessoScreen extends StatelessWidget {
  const InserisciSpesaSuccessoScreen({super.key});

  static const String routeName = '/spese/successo';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final memberFlow = args is InserisciSpesaSuccessoArgs && args.memberFlow;

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: Stack(
        children: [
          // Semi-transparent background overlay
          Opacity(
            opacity: 0.50,
            child: Container(
              width: AppSizes.p403,
              height: AppSizes.p848,
              color: AppColors.textMutedLight,
            ),
          ),

          // Success dialog container
          Center(
            child: SafeArea(
              child: Container(
                width: AppSizes.p303,
                height: AppSizes.p424,
                decoration: ShapeDecoration(
                  color: AppColors.darkBackground,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: AppSizes.p3,
                      color: AppColors.textMutedDark,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radius10),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Checkmark icon
                    Container(
                      width: AppSizes.p80,
                      height: AppSizes.p80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.statusSuccess,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check,
                        size: AppSizes.p60,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // Success title
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
                      child: Text(
                        'Spesa aggiunta!',
                        style: TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: AppSizes.p24,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p12),

                    // Description
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
                      child: Text(
                        'La spesa è stata aggiunta. I coinquilini sono stati notificati',
                        style: TextStyle(
                          color: AppColors.textMutedSoft,
                          fontSize: AppSizes.p14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p32),

                    // Back to spese button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p24,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pushReplacementNamed(
                                memberFlow
                                    ? ListaSpeseMembroScreen.routeName
                                    : ListaSpeseAdminScreen.routeName,
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusInfo,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.p12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius8,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Torna alle spese',
                            style: TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: AppSizes.p16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
