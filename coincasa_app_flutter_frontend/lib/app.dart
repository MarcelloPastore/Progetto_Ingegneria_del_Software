import 'package:flutter/material.dart';

import 'core/services/session_manager.dart';
import 'core/state/active_casa.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common/no_connection_screen.dart';
import 'features/auth/auth.dart';
import 'features/auth/screens/gestione_account_screen.dart';
import 'features/casa/casa.dart';
import 'features/dashboard/dashboard.dart';
import 'features/problemi/problemi.dart';
import 'features/scadenze/scadenze.dart';
import 'features/spese/spese.dart';
import 'features/turni/turni.dart';

/// Observer globale usato dalle schermate per rilevare
/// il ritorno al focus (didPopNext) e aggiornare i dati.
/// Usa ModalRoute[dynamic] perché i named routes restituiscono ModalRoute[dynamic].
final RouteObserver<ModalRoute<dynamic>> appRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        navigatorKey: navigatorKey,
        navigatorObservers: [appRouteObserver],
        home: const _AppStartupScreen(),
        routes: {
          NoConnectionScreen.routeName: (_) => const NoConnectionScreen(),
          '/login': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/spese': (_) => const SpeseScreen(),
          ListaSpeseAdminScreen.routeName: (_) => const ListaSpeseAdminScreen(),
          ListaSpeseMembroScreen.routeName: (_) =>
              const ListaSpeseMembroScreen(),
          DettaglioSpesaAdminScreen.routeName: (_) =>
              const DettaglioSpesaAdminScreen(),
          DettaglioSpesaDebitoreScreen.routeName: (_) =>
              const DettaglioSpesaDebitoreScreen(),
          PareggiaContiScreen.routeName: (_) => const PareggiaContiScreen(),
          ModificheSpeseNegataScreen.routeName: (_) =>
              const ModificheSpeseNegataScreen(),
          ModificheSpeseSuccessoScreen.routeName: (_) =>
              const ModificheSpeseSuccessoScreen(),
          EliminaSpesaScreen.routeName: (_) => const EliminaSpesaScreen(),
          ModificaSpesaAdminScreen.routeName: (_) =>
              const ModificaSpesaAdminScreen(),
          NessunaSpeseRegistrataScreen.routeName: (_) =>
              const NessunaSpeseRegistrataScreen(),
          InserisciSpesaScreen.routeName: (_) => const InserisciSpesaScreen(),
          InserisciSpesaMembroScreen.routeName: (_) =>
              const InserisciSpesaMembroScreen(),
          InserisciSpesaSuccessoScreen.routeName: (_) =>
              const InserisciSpesaSuccessoScreen(),
          '/turni': (_) => const ListaTurniScreen(),
          DettaglioTurnoAdminScreen.routeName: (_) =>
              const DettaglioTurnoAdminScreen(),
          AssegnaAMeSuccessScreen.routeName: (_) =>
              const AssegnaAMeSuccessScreen(),
          TurnoRimossoScreen.routeName: (_) => const TurnoRimossoScreen(),
          TurnoCreateScreen.routeName: (_) => const TurnoCreateScreen(),
          TurnoSalvatoConSuccessoScreen.routeName: (_) =>
              const TurnoSalvatoConSuccessoScreen(),
          '/scadenze': (_) => const ListaScadenze(),
          '/problemi': (_) => const ProblemiHomeScreen(),
          SegnalaProblemaScreen.routeName: (_) => const SegnalaProblemaScreen(),
          ProblemaDettaglioScreen.routeName: (_) =>
              const ProblemaDettaglioScreen(),
          DeassegnazioneSuccessoScreen.routeName: (_) =>
              const DeassegnazioneSuccessoScreen(),
          '/casa': (_) => const ListaCaseScreen(),
          GestioneAccountScreen.routeName: (_) => const GestioneAccountScreen(),
        },
      ),
    );
  }
}

class _AppStartupScreen extends StatefulWidget {
  const _AppStartupScreen();

  @override
  State<_AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<_AppStartupScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasSession = await SessionManager.restore();
    if (!mounted) return;

    if (hasSession) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF100D22),
    );
  }
}
