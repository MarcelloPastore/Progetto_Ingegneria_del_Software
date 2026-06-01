import 'package:flutter/material.dart';

import 'core/state/active_casa.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth.dart';
import 'features/casa/casa.dart';
import 'features/dashboard/dashboard.dart';
import 'features/problemi/problemi.dart';
import 'features/scadenze/scadenze.dart';
import 'features/spese/spese.dart';
import 'features/turni/turni.dart';
import 'core/utils/route_observer.dart';

class CoinCasaApp extends StatelessWidget {
  CoinCasaApp({super.key});

  final ActiveCasaController _activeCasaController = ActiveCasaController();

  @override
  Widget build(BuildContext context) {
    return ActiveCasaScope(
      controller: _activeCasaController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorObservers: [appRouteObserver],
        home: const LoginScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/spese': (_) => const SpeseScreen(),
          '/turni': (_) => const ListaTurniScreen(),
          DettaglioTurnoAdminScreen.routeName: (_) =>
              const DettaglioTurnoAdminScreen(),
          AssegnaAMeSuccessScreen.routeName: (_) =>
              const AssegnaAMeSuccessScreen(),
          TurnoRimossoScreen.routeName: (_) => const TurnoRimossoScreen(),
          TurnoCreateScreen.routeName: (_) => const TurnoCreateScreen(),
          TurnoSalvatoConSuccessoScreen.routeName: (_) =>
              const TurnoSalvatoConSuccessoScreen(),
          '/scadenze': (_) => const ScadenzeScreen(),
          '/problemi': (_) => const ProblemiScreen(),
          '/casa': (_) => const ListaCaseScreen(),
        },
      ),
    );
  }
}
