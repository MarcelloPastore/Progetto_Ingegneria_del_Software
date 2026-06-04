import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'lista_spese_admin.dart';
import 'lista_spese_membro.dart';

class SpeseScreen extends StatelessWidget {
  const SpeseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ApiProvider.casa.list(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF151127),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final caseUtente = snapshot.data;
        if (caseUtente == null || caseUtente.isEmpty) {
          return const ListaSpeseAdminScreen(); // Fallback
        }
        final activeCasaController = ActiveCasaScope.read(context);
        final casa = activeCasaController.resolveCasa(caseUtente);
        if (casa.ruolo == 'HomeAdmin' || casa.ruolo == 'SysAdmin') {
          return const ListaSpeseAdminScreen();
        } else {
          return const ListaSpeseMembroScreen();
        }
      },
    );
  }
}

