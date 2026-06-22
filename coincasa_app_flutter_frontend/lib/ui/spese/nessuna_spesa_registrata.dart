import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/ui/spese/screens/inserisci_spesa_admin.dart';

class NessunaSpeseRegistrataScreen extends StatelessWidget {
  const NessunaSpeseRegistrataScreen({super.key});

  static const String routeName = '/spese/nessuna';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSizes.p12),
              const AppScreensHeader(title: 'Spese'),
              Expanded(
                child: EmptyStateWidget(
                  icon: Image.asset(
                    'assets/Icons/carrello_spesa.png',
                    width: AppSizes.p100,
                    height: AppSizes.p100,
                    fit: BoxFit.contain,
                  ),
                  iconBackgroundColor: AppColors.statusPositive.withValues(
                    alpha: 0.1,
                  ),
                  title: 'Nessuna spesa registrata',
                  description:
                      'Aggiungi la prima spesa della casa per iniziare a dividere i costi con i coinquilini.',
                  ctaLabel: 'Inserisci spesa',
                  onCta: () => Navigator.of(
                    context,
                  ).pushNamed(InserisciSpesaScreen.routeName),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
