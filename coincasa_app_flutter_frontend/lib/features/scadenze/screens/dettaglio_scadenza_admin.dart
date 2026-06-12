import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'scadenza_form_screen.dart';

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
  final String? idScadenza;
  final String? casaId;

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
    this.idScadenza,
    this.casaId,
  });

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final data = dataScadenza ?? DateTime(2026, 6, 25);

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
          'Dettaglio scadenza',
          style: TextStyle(
            color: Color(0xFFAC86FF),
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: const Color(0xFF37325A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titolo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            descrizione,
                            style: const TextStyle(
                              color: Color(0xFFC9C9C9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Data scadenza',
                                    style: TextStyle(
                                      color: Color(0xFFC9C9C9),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(data),
                                    style: const TextStyle(
                                      color: Color(0xFFFF860E),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge(
                                text: stato,
                                color: const Color(0xFFFF860E),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _infoRow('Frequenza', frequenza),
                          if (isAdmin) ...[
                            const SizedBox(height: 8),
                            _infoRow('Ricorrente', ricorrente ? 'Sì' : 'No'),
                          ],
                          const SizedBox(height: 8),
                          _infoRow('Creata da', creatoDa),
                          const SizedBox(height: 8),
                          _infoRow('Visibile a', visibileA),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DetailActionsBar(
            modifyLabel: 'Modifica scadenza',
            deleteLabel: 'Elimina scadenza',
            backLabel: 'Torna alle scadenze',
            isCreator: isAdmin,
            onModify: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ScadenzaFormScreen.modifica(
                nome: titolo,
                descrizione: descrizione,
                data: dataScadenza,
                frequenza: frequenza,
                idScadenza: idScadenza ?? '',
                casaId: casaId ?? '',
              ),
            )),
            onDelete: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Conferma eliminazione'),
                  content: const Text(
                      'Sei sicuro di voler eliminare questa scadenza?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Annulla'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Elimina'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                final id = idScadenza;
                final cId = casaId;
                if (id != null && cId != null && id.isNotEmpty && cId.isNotEmpty) {
                  try {
                    await ApiProvider.scadenze.delete(cId, id);
                  } catch (_) {}
                }
                if (context.mounted) Navigator.of(context).maybePop();
              }
            },
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC9C9C9),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
