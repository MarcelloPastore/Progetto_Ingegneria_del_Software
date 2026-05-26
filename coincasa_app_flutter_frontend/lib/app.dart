import 'package:coincasa_app/features/auth/screens/successo_nuova_password_screen.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth.dart';
import 'features/dashboard/dashboard.dart';

class CoinCasaApp extends StatelessWidget {
  const CoinCasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const InserisciCodiceScreen(),
    );
  }
}
//LoginScreen()
//CheckEmailScreen(email: 'marco@gmail.com')
//RegisterScreen()
//AccountActivatedScreen()
//DashboardScreen()
//AttesaInvioCodiceScreen()
//ErroreCodiceNonCorrettoScreen()
//ErroreEmailNonRiconosciutaScreen() RIPRENDI DA QUI
//ErrorePasswordNonValideScreen()
//InserisciCodiceScreen()
//NuovaPasswordScreen()
//PasswordDimenticataScreen()