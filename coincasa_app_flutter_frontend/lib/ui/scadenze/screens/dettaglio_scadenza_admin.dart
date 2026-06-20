import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/delete_confirm_dialog.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/info_row.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/domain/viewmodel/scadenze_viewmodel.dart';
import 'scadenza_form_screen.dart';

class DettaglioScadenzaAdminScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final data = dataScadenza ?? DateTime(2026, 6, 25);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          systemOverlayStyle: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.brandAccent),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Dettaglio scadenza',
            style: TextStyle(
              color: AppColors.brandAccent,
              fontSize: AppSizes.p20,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: cs.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius10),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titolo,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: AppSizes.p20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSizes.p8),
                            Text(
                              descrizione,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: AppSizes.p16,
                              ),
                            ),
                            const SizedBox(height: AppSizes.p16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data scadenza',
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: AppSizes.p18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: AppSizes.p6),
                                    Text(
                                      _formatDate(data),
                                      style: TextStyle(
                                        color: AppColors.lockOrange,
                                        fontSize: AppSizes.p16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                StatusBadge(
                                  text: stato,
                                  color: AppColors.lockOrange,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.p12),
                            InfoRow(label: 'Frequenza', value: frequenza),
                            if (isAdmin) ...[
                              const SizedBox(height: AppSizes.p8),
                              InfoRow(
                                label: 'Ricorrente',
                                value: ricorrente ? 'Sì' : 'No',
                              ),
                            ],
                            const SizedBox(height: AppSizes.p8),
                            InfoRow(label: 'Creata da', value: creatoDa),
                            const SizedBox(height: AppSizes.p8),
                            InfoRow(label: 'Visibile a', value: visibileA),
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
              isCreator: false,
              canDelete: isAdmin,
              onModify: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScadenzaFormScreen.modifica(
                    nome: titolo,
                    descrizione: descrizione,
                    data: dataScadenza,
                    frequenza: frequenza,
                    idScadenza: idScadenza ?? '',
                    casaId: casaId ?? '',
                  ),
                ),
              ),
              onDelete: () => showDeleteConfirmDialog(
                context: context,
                title: 'Eliminare la scadenza?',
                description:
                    '"$titolo" verrà rimossa definitivamente. Tutti i coinquilini verranno avvisati.',
                onConfirm: () {
                  final id = idScadenza;
                  final cId = casaId;
                  if (id == null ||
                      cId == null ||
                      id.isEmpty ||
                      cId.isEmpty) {
                    return Future.value();
                  }
                  return ref
                      .read(scadenzeViewModelProvider(cId).notifier)
                      .deleteScadenza(id);
                },
                onSuccess: () => Navigator.of(context).maybePop(),
              ),
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/scadenze'),
      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSizes.p6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w600,
          fontSize: AppSizes.p14,
        ),
      ),
    );
  }
}
