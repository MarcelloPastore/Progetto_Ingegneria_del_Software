import 'package:flutter/material.dart';

import 'core/api/api_provider.dart';
import 'core/models/casa.dart';
import 'core/services/session_manager.dart';
import 'core/state/active_casa.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common/no_connection_screen.dart';
import 'features/auth/auth.dart';
import 'features/auth/screens/elimina_account_success_screen.dart';
import 'features/auth/screens/gestione_account_screen.dart';
import 'features/auth/screens/modifica_password_screen.dart';
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
  const CoinCasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ActiveCasaScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        navigatorKey: navigatorKey,
        navigatorObservers: [appRouteObserver],
        home: const _AppStartupScreen(),
        routes: {
          NoConnectionScreen.routeName: (_) => const NoConnectionScreen(),
          '/login': (_) => const LoginScreen(),
          // Ogni navigazione verso /dashboard passa per _HouseGuard.
          // Se l'utente non ha case, viene reindirizzato a CasaWelcomeScreen.
          '/dashboard': (_) => const _HouseGuard(),
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
          ModificaProblemaScreen.routeName: (_) =>
              const ModificaProblemaScreen(),
          EliminaProblemaScreen.routeName: (_) => const EliminaProblemaScreen(),
          '/casa': (_) => const ListaCaseScreen(),
          GestioneAccountScreen.routeName: (_) => const GestioneAccountScreen(),
          EliminaAccountSuccessScreen.routeName: (_) =>
              const EliminaAccountSuccessScreen(),
          ModificaPasswordScreen.routeName: (_) =>
              const ModificaPasswordScreen(),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guard: intercetta /dashboard e verifica che l'utente abbia almeno una casa.
// Se non ne ha nessuna, reindirizza a CasaWelcomeScreen rimuovendo tutto lo
// stack — è impossibile tornare indietro alla dashboard senza una casa.
// ---------------------------------------------------------------------------

class _HouseGuard extends StatefulWidget {
  const _HouseGuard();

  @override
  State<_HouseGuard> createState() => _HouseGuardState();
}

class _HouseGuardState extends State<_HouseGuard> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    List<dynamic> cases = [];
    bool apiError = false;
    try {
      cases = await ApiProvider.casa.list();
    } catch (_) {
      apiError = true;
    }
    if (!mounted) return;

    if (apiError || cases.isNotEmpty) {
      // Ha case (o errore di rete: non blocchiamo l'utente per un problema API).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      );
    } else {
      // Nessuna casa: rimuovi tutto lo stack e porta al welcome.
      final client = ApiProvider.client;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CasaWelcomeScreen(
            email: client.currentUserEmail ?? '',
            userId: client.currentUserId,
            username: client.currentUserUsername,
            displayName: client.currentUserDisplayName,
          ),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Schermata di attesa mentre il check è in corso.
    return const Scaffold(backgroundColor: Color(0xFF100D22));
  }
}

// ---------------------------------------------------------------------------
// Startup: ripristina la sessione, verifica le case, instrada di conseguenza.
// Naviga direttamente a DashboardScreen (non via named route) quando le case
// sono già state verificate qui, evitando una doppia chiamata API.
// ---------------------------------------------------------------------------

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

    if (!hasSession) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Ripristina la casa attiva e il ruolo nel controller (senza fare rete).
    final restoredCasaId = ApiProvider.client.currentCasaId;
    final restoredRuolo = ApiProvider.client.currentCasaRuolo;
    if (restoredCasaId != null && restoredCasaId.isNotEmpty) {
      ActiveCasaScope.read(
        context,
      ).setCasaContext(casaId: restoredCasaId, ruolo: restoredRuolo ?? '');
    }

    List<Casa> caseUtente = [];
    try {
      caseUtente = await ApiProvider.casa.list();
    } catch (_) {
      // Errore di rete: accedi alla dashboard come fallback.
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      );
      return;
    }
    if (!mounted) return;

    if (caseUtente.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      );
    } else {
      // Nessuna casa: vai al welcome screen.
      final client = ApiProvider.client;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CasaWelcomeScreen(
            email: client.currentUserEmail ?? '',
            userId: client.currentUserId,
            username: client.currentUserUsername,
            displayName: client.currentUserDisplayName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Color(0xFF100D22));
  }
}
