import 'package:flutter/material.dart';
import 'ui/screens/Autenticazione/account_activated_screen.dart';
import 'ui/screens/Autenticazione/login_screen.dart';

class CoinCasaApp extends StatelessWidget {
  const CoinCasaApp({super.key});

  static const bool _showAccountActivated = bool.fromEnvironment(
    'SHOW_ACCOUNT_ACTIVATED',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090616),
      ),
      home: _showAccountActivated
          ? const AccountActivatedScreen()
          : const LoginScreen(),
    );
  }
}
