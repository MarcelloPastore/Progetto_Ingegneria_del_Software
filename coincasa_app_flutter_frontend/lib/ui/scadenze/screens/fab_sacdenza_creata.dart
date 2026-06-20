import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class FabScadenzaCreataPanel extends StatelessWidget {
  const FabScadenzaCreataPanel({
    super.key,
    required this.onBackToScadenze,
    required this.onAddAnother,
  });

  final VoidCallback onBackToScadenze;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p12,
          AppSizes.p26,
          AppSizes.p12,
          AppSizes.p30,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.p8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: AppSizes.p4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '✔',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppSizes.p76, height: 1),
            ),
            const SizedBox(height: AppSizes.p20),
            Text(
              'Scadenza salvata!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppSizes.p19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.p14),
            Text(
              'Tutti i coinquilini di Casa Verdi sono\nstati notificati.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: AppSizes.p15,
                height: AppSizes.p1_25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.p28),
            SizedBox(
              height: AppSizes.p40,
              child: ElevatedButton(
                onPressed: onBackToScadenze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.p14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Torna alle scadenze',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: AppSizes.p17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p10),
            SizedBox(
              height: AppSizes.p40,
              child: OutlinedButton(
                onPressed: onAddAnother,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.featureAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.p14),
                  ),
                ),
                child: Text(
                  "Aggiungi un'altra",
                  style: TextStyle(
                    color: AppColors.featureAccent,
                    fontSize: AppSizes.p16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
