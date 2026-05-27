import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/casa/casa.dart';

class CoinCasaApp extends StatelessWidget {
  const CoinCasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CasaWelcomeScreen(email: 'marc@example.com'),
    );
  }
}

//schermate modulo casa da testare:
//ArchivioDocumentiVuotoScreen
//CaricaDocumentiScreen
//ProfiloCoinquilinoScreen
//ArchivioDocumentiScreen
//CasaCreataSuccessoScreen
