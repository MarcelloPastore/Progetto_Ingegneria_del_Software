import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

Future<void> showProblemaSuccessoFABDialog(
  BuildContext context, {
  required bool assignedToMe,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => ProblemaSuccessoFABDialog(assignedToMe: assignedToMe),
  );
}

class ProblemaSuccessoFABDialog extends StatelessWidget {
  const ProblemaSuccessoFABDialog({super.key, required this.assignedToMe});

  final bool assignedToMe;

  @override
  Widget build(BuildContext context) {
    final title = assignedToMe
        ? 'Problema assegnato a te!'
        : 'Problema segnalato!';
    final description = assignedToMe
        ? 'Ti sei assegnato correttamente questo problema. Da ora risulti come assegnatario corrente'
        : 'Il problema è stato segnalato correttamente. Qualcuno se ne occuperà.';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p18,
          AppSizes.p18,
          AppSizes.p18,
          AppSizes.p20,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(AppSizes.radius24),
          border: Border.all(color: AppColors.brandAccent, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSizes.p18),
              _SuccessMark(),
              const SizedBox(height: AppSizes.p30),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSizes.p18),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMutedLarge.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: 21,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: AppSizes.p42),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p14,
                  vertical: AppSizes.p22,
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
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p56),
              SizedBox(
                width: double.infinity,
                height: 76,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
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
                          textAlign: TextAlign.center,
                          style: AppTextStyles.screenTitleStrong.copyWith(
                            color: AppColors.textOnDark,
                            fontSize: 24,
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
    );
  }
}

class _SuccessMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        color: AppColors.statusPositive,
        size: 118,
      ),
    );
  }
}
