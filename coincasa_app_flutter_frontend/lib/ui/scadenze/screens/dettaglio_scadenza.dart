import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/delete_confirm_dialog.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/info_row.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/domain/viewmodel/scadenze_viewmodel.dart';
import 'package:coincasa_app/ui/scadenze/screens/lista_scadenze.dart';
import 'form_modifica_scadenza.dart';

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
  final bool isCreator;
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
    this.isCreator = false,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Se abbiamo idScadenza e casaId, osserviamo il provider per aggiornamenti real-time
    final AsyncValue<ScadenzeData>? dataAsync =
        (idScadenza != null && casaId != null)
        ? ref.watch(scadenzeDataProvider(casaId!))
        : null;

    ScadenzaItem? updatedItem;
    if (dataAsync != null && dataAsync.hasValue) {
      final data = dataAsync.value!;
      // Cerchiamo l'item nelle liste inScadenza o prossime
      final items = [...data.inScadenza, ...data.prossime];
      try {
        updatedItem = items.firstWhere((i) => i.scadenzaObj?.id == idScadenza);
      } catch (_) {
        // Item non trovato
      }
    }

    final displayTitolo = updatedItem?.title ?? titolo;
    final displayDescrizione =
        updatedItem?.scadenzaObj?.descrizione ?? descrizione;
    final displayData =
        updatedItem?.sortDate ?? dataScadenza ?? DateTime(2026, 6, 25);
    final displayStato = updatedItem?.badgeText ?? stato;
    final displayFrequenza = updatedItem?.frequenza ?? frequenza;
    final displayRicorrente =
        updatedItem?.scadenzaObj?.isRicorrente ?? ricorrente;

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
                              displayTitolo,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: AppSizes.p20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSizes.p8),
                            Text(
                              displayDescrizione,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: AppSizes.p16,
                              ),
                            ),
                            const SizedBox(height: AppSizes.p16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      _formatDate(displayData),
                                      style: TextStyle(
                                        color: AppColors.lockOrange,
                                        fontSize: AppSizes.p16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                StatusBadge(
                                  text: displayStato,
                                  color: AppColors.lockOrange,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.p12),
                            InfoRow(
                              label: 'Frequenza',
                              value: displayFrequenza,
                            ),
                            if (isAdmin) ...[
                              const SizedBox(height: AppSizes.p8),
                              InfoRow(
                                label: 'Ricorrente',
                                value: displayRicorrente ? 'Sì' : 'No',
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
              isCreator: isCreator,
              canDelete: isAdmin,
              onModify: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ScadenzaFormScreen.modifica(
                      nome: displayTitolo,
                      descrizione: displayDescrizione,
                      data: displayData,
                      frequenza: displayFrequenza,
                      idScadenza: idScadenza ?? '',
                      casaId: casaId ?? '',
                    ),
                  ),
                );
                if (result == true && casaId != null) {
                  ref.invalidate(scadenzeDataProvider(casaId!));
                }
              },
              onDelete: () => showDeleteConfirmDialog(
                context: context,
                title: 'Eliminare la scadenza?',
                description:
                    '"$displayTitolo" verrà rimossa definitivamente. Tutti i coinquilini verranno avvisati.',
                onConfirm: () {
                  final id = idScadenza;
                  final cId = casaId;
                  if (id == null || cId == null || id.isEmpty || cId.isEmpty) {
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
