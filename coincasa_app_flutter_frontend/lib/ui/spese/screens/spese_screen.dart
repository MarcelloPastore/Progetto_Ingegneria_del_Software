import 'package:flutter/material.dart';
import 'lista_spese.dart';

/// Schermata principale delle spese.
/// Utilizza sempre [ListaSpeseAdminScreen] per tutti gli utenti;
/// l'unica funzionalità riservata agli HomeAdmin è l'impostazione
/// della spesa ricorrente, gestita direttamente in [InserisciSpesaScreen].
class SpeseScreen extends StatelessWidget {
  const SpeseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListaSpeseAdminScreen();
  }
}
