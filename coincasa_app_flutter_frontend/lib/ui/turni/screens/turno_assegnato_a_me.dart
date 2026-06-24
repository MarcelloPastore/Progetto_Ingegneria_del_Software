import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class AssegnaAMeSuccessScreen extends StatelessWidget {
  const AssegnaAMeSuccessScreen({super.key});

  static const routeName = '/turni/assegna-a-me/successo';

  @override
  Widget build(BuildContext context) {
    final String? username =
        ModalRoute.of(context)?.settings.arguments as String?;
    final String title = username != null && username.isNotEmpty
        ? 'Turno assegnato a $username!'
        : 'Turno assegnato a te!';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p24,
            AppSizes.p60,
            AppSizes.p24,
            AppSizes.p32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/Icons/green_check_mark.png',
                width: AppSizes.p110,
                height: AppSizes.p110,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSizes.p35),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  fontSize: AppSizes.p25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSizes.p56),
              Text(
                'Il turno e stato assegnato con\n'
                'successo. La rotazione automatica e\n'
                'attiva di default e i turni successivi\n'
                'restano invariati.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: AppSizes.p19,
                  height: 1.16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p56),
              const _NotifiedBanner(),
              const SizedBox(height: AppSizes.p18),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/turni'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandAccent,
                  side: const BorderSide(
                    color: AppColors.brandSecondary,
                    width: AppSizes.p1_8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                ),
                child: Text(
                  'Ritorna ai turni',
                  style: AppTextStyles.buttonCompact.copyWith(
                    color: AppColors.brandAccent,
                    fontSize: AppSizes.p19,
                    fontWeight: FontWeight.w900,
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

class _NotifiedBanner extends StatelessWidget {
  const _NotifiedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.p56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.statusPositive,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(color: AppColors.statusPositive, width: AppSizes.p2),
      ),
      child: Text(
        'Tutti i coinquilini sono stati avvisati',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.statusPositive,
          fontSize: AppSizes.p16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
