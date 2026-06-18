import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/empty_state_widget.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/inserisci_spesa_admin.dart';

class NessunaSpeseRegistrataScreen extends StatelessWidget {
  const NessunaSpeseRegistrataScreen({super.key});

  static const String routeName = '/spese/nessuna';

  Future<Casa?> _loadActiveCasa(BuildContext context) async {
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }
    return activeCasaController.resolveCasa(caseUtente);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF09051F),
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
        body: SafeArea(
          child: FutureBuilder<Casa?>(
            future: _loadActiveCasa(context),
            builder: (context, snapshot) {
              final casaNome = snapshot.data?.nome.trim().isNotEmpty == true
                  ? snapshot.data!.nome.trim()
                  : 'Casa';

              return EmptyStateWidget(
                icon: Image.asset(
                  'assets/Icons/carrello_spesa.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                iconBackgroundColor: AppColors.statusPositive.withValues(alpha: 0.1),
                title: 'Nessuna spesa registrata',
                description:
                    'Aggiungi la prima spesa della casa per iniziare a dividere i costi con i coinquilini.',
                ctaLabel: 'Inserisci spesa',
                onCta: () => Navigator.of(context).pushNamed(InserisciSpesaScreen.routeName),
              );
            },
          ),
        ),
      ),
    );
  }
}
