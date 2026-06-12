import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

Future<void> showProblemaSuccessoFABDialog(
  BuildContext context, {
  required bool assignedToMe,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ProblemaSuccessoFABDialog(assignedToMe: assignedToMe),
    ),
  );
}

class ProblemaSuccessoFABDialog extends StatelessWidget {
  const ProblemaSuccessoFABDialog({super.key, required this.assignedToMe});

  final bool assignedToMe;

  @override
  Widget build(BuildContext context) {
    final title = assignedToMe ? 'Problema assegnato a te!' : 'Problema segnalato!';
    final description = assignedToMe
        ? 'Ti sei assegnato correttamente questo problema. Da ora risulti come assegnatario corrente.'
        : 'Il problema è stato segnalato correttamente. Qualcuno se ne occuperà.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p24,
              vertical: AppSizes.p30,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Checkmark
                Center(child: _SuccessMark()),

                const SizedBox(height: AppSizes.p30),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.textOnDark,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: AppSizes.p16),

                // Description
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMutedLarge.copyWith(
                    color: AppColors.textMutedLight,
                    fontSize: 18,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: AppSizes.p42),

                // Green notification box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p14,
                    vertical: AppSizes.p20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBright.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(AppSizes.radius14),
                    border: Border.all(color: AppColors.statusPositive, width: 2),
                  ),
                  child: Text(
                    'Tutti i coinquilini sono stati avvisati.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const Spacer(),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 66,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.brandAccent, AppColors.brandPrimary],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
                        onTap: () => Navigator.of(context).pop(),
                        child: Center(
                          child: Text(
                            'Vai ai Problemi',
                            style: AppTextStyles.screenTitleStrong.copyWith(
                              color: AppColors.textOnDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
    );
  }
}

class _SuccessMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.check_circle_rounded,
      color: AppColors.statusPositive,
      size: 128,
    );
  }
}
