import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/empty_state_widget.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/ui/spese/screens/inserisci_spesa_admin.dart';

class NessunaSpeseRegistrataScreen extends StatelessWidget {
  const NessunaSpeseRegistrataScreen({super.key});

  static const String routeName = '/spese/nessuna';

  @override
  Widget build(BuildContext context) {
    final casaNome = ActiveCasaScope.read(context).selectedCasa?.nome ?? 'Casa';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
        body: SafeArea(
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
            title: 'Nessuna spesa registrata in $casaNome',
            description:
                'Aggiungi la prima spesa della casa per iniziare a dividere i costi con i coinquilini.',
            ctaLabel: 'Inserisci spesa',
            onCta: () =>
                Navigator.of(context).pushNamed(InserisciSpesaScreen.routeName),
          ),
        ),
      ),
    );
  }
}
