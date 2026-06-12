import 'package:flutter/material.dart';

class FabScadenzaCreataPanel extends StatelessWidget {
  const FabScadenzaCreataPanel({
    super.key,
    required this.onBackToScadenze,
    required this.onAddAnother,
  });

  final VoidCallback onBackToScadenze;
  final VoidCallback onAddAnother;

  static const _primary = Color(0xFF5A2BBF);
  static const _accent = Color(0xFF996CFA);
  static const _surface = Color(0xFF09051F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 26, 12, 30),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '✔',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 76, height: 1),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scadenza salvata!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tutti i coinquilini di Casa Verdi sono\nstati notificati.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFC8C2D7),
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: onBackToScadenze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Torna alle scadenze',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: onAddAnother,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _accent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Aggiungi un'altra",
                  style: TextStyle(
                    color: _accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
