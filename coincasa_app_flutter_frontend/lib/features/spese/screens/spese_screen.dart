import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'lista_spese_admin.dart';
import 'lista_spese_membro.dart';

class SpeseScreen extends StatefulWidget {
  const SpeseScreen({super.key});

  @override
  State<SpeseScreen> createState() => _SpeseScreenState();
}

class _SpeseScreenState extends State<SpeseScreen> {
  /// Cache statica del ruolo: sopravvive ai pushNamedAndRemoveUntil.
  static String? _cachedRuolo;

  bool _isAdmin = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // Controlla se il ruolo è già noto in modo sincrono
    // (disponibile dopo che DashboardScreen ha chiamato resolveCasa).
    final controller = ActiveCasaScope.read(context);
    final casaCached = controller.selectedCasa;
    if (casaCached != null && casaCached.ruolo.isNotEmpty) {
      _cachedRuolo = casaCached.ruolo;
    }
    _isAdmin = _resolveIsAdmin(_cachedRuolo);

    // Se il ruolo non è ancora noto, avvia fetch in background
    // e aggiorna senza mostrare uno spinner.
    if (_cachedRuolo == null) {
      _fetchRuoloInBackground();
    }
  }

  static bool _resolveIsAdmin(String? ruolo) {
    return ruolo == 'HomeAdmin' || ruolo == 'SysAdmin';
  }

  Future<void> _fetchRuoloInBackground() async {
    try {
      final caseUtente = await ApiProvider.casa.list();
      if (!mounted || caseUtente.isEmpty) return;
      final controller = ActiveCasaScope.read(context);
      final casa = controller.resolveCasa(caseUtente);
      _cachedRuolo = casa.ruolo;
      if (mounted) {
        setState(() {
          _isAdmin = _resolveIsAdmin(_cachedRuolo);
        });
      }
    } catch (_) {
      // Mantieni il fallback già mostrato.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) {
      return const ListaSpeseAdminScreen();
    }
    return const ListaSpeseMembroScreen();
  }
}
