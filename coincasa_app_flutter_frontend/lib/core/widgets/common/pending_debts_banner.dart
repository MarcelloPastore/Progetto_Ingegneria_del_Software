import 'package:flutter/material.dart';

import 'package:coincasa_app/core/models/spesa.dart';

/// Banner giallo che avvisa l'utente di quote pendenti non saldate.
/// Riutilizzabile in qualsiasi schermata che richieda questo avviso
/// (es. eliminazione account, abbandono casa, …).
///
/// [spese] — lista di spese su cui l'utente ha ancora quote da pagare.
class PendingDebtsBanner extends StatelessWidget {
  const PendingDebtsBanner({super.key, required this.spese});

  final List<Spesa> spese;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2200),
        border: Border.all(color: const Color(0xFFD4A800), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Intestazione banner ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFD31A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ricordati di pagare le quote pendenti!',
                    style: TextStyle(
                      color: Color(0xFFFFD31A),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (spese.isNotEmpty) ...[
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF4A3B00),
              indent: 14,
              endIndent: 14,
            ),

            // ── Lista spese pendenti ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                children: [
                  for (int i = 0; i < spese.length; i++) ...[
                    _DebtRow(spesa: spese[i]),
                    if (i < spese.length - 1)
                      const Divider(
                        height: 10,
                        thickness: 1,
                        color: Color(0xFF3A2E00),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.spesa});

  final Spesa spesa;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.receipt_long_rounded,
          color: Color(0xFFD4A800),
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            spesa.descrizione.isNotEmpty ? spesa.descrizione : 'Spesa',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE8C840),
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '€${spesa.importo.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Color(0xFFFFD31A),
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
