import 'package:flutter/material.dart';

import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/pending_debts_banner.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Dialog di conferma "Lascia la casa"
// ──────────────────────────────────────────────────────────────────────────────

Future<bool?> showLasciaCasaDialog(
  BuildContext context, {
  required String nomeCasa,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (_) => _LasciaCasaDialog(nomeCasa: nomeCasa),
  );
}

class _LasciaCasaDialog extends StatelessWidget {
  const _LasciaCasaDialog({required this.nomeCasa});

  final String nomeCasa;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SingleChildScrollView(
          child: _LasciaCard(nomeCasa: nomeCasa),
        ),
      ),
    );
  }
}

class _LasciaCard extends StatelessWidget {
  const _LasciaCard({required this.nomeCasa});

  final String nomeCasa;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF151127),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2243)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emoji casa
          const Center(
            child: Text('🏠', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 16),

          const Text(
            'Esci dalla casa?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Stai per abbandonare $nomeCasa. Non avrai più accesso alle spese, turni e scadenze condivise.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFDAD6E7),
              fontSize: 17,
              height: 1.22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          // Warning box
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF5B3F21),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFA726), width: 1.5),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFC94D),
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Questa azione non può essere annullata.',
                    style: TextStyle(
                      color: Color(0xFFFFC94D),
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Conferma
          SizedBox(
            height: 58,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Si, esci dalla casa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Annulla
          SizedBox(
            height: 58,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1336),
                foregroundColor: const Color(0xFFD8B8FF),
                side: const BorderSide(color: Color(0xFF8A35FF), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Annulla',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Schermata di conferma uscita
// ──────────────────────────────────────────────────────────────────────────────

class LasciaCasaSuccessScreen extends StatelessWidget {
  const LasciaCasaSuccessScreen({
    super.key,
    required this.nomeCasa,
    this.spesePendenti = const [],
  });

  final String nomeCasa;

  /// Spese in cui l'utente ha ancora quote non pagate.
  /// Se non vuota, viene mostrato il [PendingDebtsBanner].
  final List<Spesa> spesePendenti;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),

              // Checkmark
              Image.asset(
                'assets/Icons/check.png',
                width: 100,
                height: 100,
                errorBuilder: (_, e, s) => const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4ADE80),
                  size: 100,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Sei uscito da $nomeCasa',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 22),

              // Box descrizione
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF4ADE80),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'Hai abbandonato la casa con successo. Ora puoi creare una nuova casa o entrare in una esistente.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Reminder debiti
              if (spesePendenti.isNotEmpty) ...[
                const SizedBox(height: 16),
                PendingDebtsBanner(spese: spesePendenti),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/dashboard', (_) => false),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
