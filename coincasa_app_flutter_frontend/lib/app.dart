import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth.dart';
import 'features/casa/casa.dart';
import 'features/dashboard/dashboard.dart';
import 'features/problemi/problemi.dart';
import 'features/scadenze/scadenze.dart';
import 'features/spese/spese.dart';
import 'features/turni/turni.dart';
import 'features/turni/screens/lista_turni_vuota.dart';

class CoinCasaApp extends StatelessWidget {
  const CoinCasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ListaTurniScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/spese': (_) => const SpeseScreen(),
        '/turni': (_) => const ListaTurniScreen(),
        '/turni/vuota': (_) => const ListaTurniVuotaScreen(),
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
    );
  }
}

//schermate modulo casa da testare:
//ArchivioDocumentiVuotoScreen
//CaricaDocumentiScreen
//ProfiloCoinquilinoScreen
//ArchivioDocumentiScreen
//CasaCreataSuccessoScreen

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth.dart';
import 'features/casa/casa.dart';
import 'features/dashboard/dashboard.dart';
import 'features/problemi/problemi.dart';
import 'features/scadenze/scadenze.dart';
import 'features/spese/spese.dart';
import 'features/turni/turni.dart';
import 'features/turni/screens/lista_turni_vuota.dart';

class CoinCasaApp extends StatelessWidget {
  const CoinCasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ListaTurniScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/spese': (_) => const SpeseScreen(),
        '/turni': (_) => const ListaTurniScreen(),
        '/turni/vuota': (_) => const ListaTurniVuotaScreen(),
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
    );
  }
}

//schermate modulo casa da testare:
//ArchivioDocumentiVuotoScreen
//CaricaDocumentiScreen
//ProfiloCoinquilinoScreen
//ArchivioDocumentiScreen
//CasaCreataSuccessoScreen

