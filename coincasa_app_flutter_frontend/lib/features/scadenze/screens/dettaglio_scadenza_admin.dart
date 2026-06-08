import 'package:flutter/material.dart';

class DettaglioScadenzaAdminScreen extends StatelessWidget {
  final String titolo;
  final String descrizione;
  final DateTime? dataScadenza;
  final String stato;
  final String frequenza;
  final bool ricorrente;
  final String creatoDa;
  final String visibileA;
  final bool isAdmin;

  const DettaglioScadenzaAdminScreen({
    super.key,
    this.titolo = 'Revisione caldaia',
    this.descrizione = 'Revisione annuale obbligatoria',
    this.dataScadenza,
    this.stato = 'In scadenza',
    this.frequenza = 'Annuale',
    this.ricorrente = true,
    this.creatoDa = 'Tu (Admin)',
    this.visibileA = 'Tutti i coinquilini',
    this.isAdmin = true,
  });

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  TextStyle get _labelStyle => const TextStyle(
        color: Color(0xFFC9C9C9),
        fontSize: 18,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      );

  TextStyle get _valueStyle => const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final data = dataScadenza ?? DateTime(2026, 6, 11);

    return Scaffold(
      backgroundColor: const Color(0xFF151127),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFAC86FF)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Dettaglio Scadenza',
          style: TextStyle(
            color: Color(0xFFAC86FF),
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFF37325A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titolo, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(descrizione, style: const TextStyle(color: Color(0xFFC9C9C9), fontSize: 16)),
                    const SizedBox(height: 16),

                    // Row: Data scadenza + badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Data scadenza', style: _labelStyle),
                            const SizedBox(height: 6),
                            Text(_formatDate(data), style: const TextStyle(color: Color(0xFFFF860E), fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        StatusBadge(text: stato, color: const Color(0xFFFF860E)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _infoRow('Frequenza', frequenza),
                    const SizedBox(height: 8),
                    if (isAdmin) ...[
                      _infoRow('Ricorrente', ricorrente ? 'Sì (365 gg)' : 'No'),
                      const SizedBox(height: 8),
                    ],
                    _infoRow('Creata da', creatoDa),
                    const SizedBox(height: 8),
                    _infoRow('Visibile a', visibileA),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: width * 0.8,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5228AD),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        // TODO: naviga alla schermata di modifica
                      },
                      child: const Text('Modifica', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: width * 0.8,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAD2828),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Conferma eliminazione'),
                            content: const Text('Sei sicuro di voler eliminare questa scadenza?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Elimina')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          // TODO: chiamare API di eliminazione
                        }
                      },
                      child: const Text('Elimina', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value, style: _valueStyle, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({Key? key, required this.text, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
