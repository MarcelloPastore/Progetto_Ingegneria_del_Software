import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/scadenza.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/ui/spese/screens/dettaglio_spesa_admin.dart';
import 'package:coincasa_app/ui/turni/screens/dettaglio_turno_admin.dart';
import 'dettaglio_scadenza_admin.dart';
import 'scadenza_form_screen.dart';

// ---------------------------------------------------------------------------
// Color coding — same as dashboard calendar
// ---------------------------------------------------------------------------

const _colorTurno = AppColors.statusInfo;
const _colorSpesa = AppColors.keyYellow;
const _colorScadenza = AppColors.statusNegative;

enum ScadenzaTipo { turno, spesa, scadenza }

// ---------------------------------------------------------------------------
// Display model
// ---------------------------------------------------------------------------

class ScadenzaItem {
  const ScadenzaItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.badgeText,
    required this.tipo,
    required this.sortDate,
    this.frequenza = 'Non ripetere',
    this.turno,
    this.spesa,
    this.scadenzaObj,
  });

  final String title;
  final String subtitle;
  final String date;
  final String badgeText;
  final ScadenzaTipo tipo;
  final DateTime sortDate;
  final String frequenza;
  final Turno? turno;
  final Spesa? spesa;
  final Scadenza? scadenzaObj;

  Color get sideColor => switch (tipo) {
    ScadenzaTipo.turno => _colorTurno,
    ScadenzaTipo.spesa => _colorSpesa,
    ScadenzaTipo.scadenza => _colorScadenza,
  };

  String get tipoLabel => switch (tipo) {
    ScadenzaTipo.turno => 'Turno',
    ScadenzaTipo.spesa => 'Spesa',
    ScadenzaTipo.scadenza => 'Scadenza',
  };
}

// ---------------------------------------------------------------------------
// Internal async data
// ---------------------------------------------------------------------------

class ScadenzeData {
  const ScadenzeData({required this.inScadenza, required this.prossime});
  final List<ScadenzaItem> inScadenza;
  final List<ScadenzaItem> prossime;
}

// ---------------------------------------------------------------------------
// Provider — aggregation logic outside the widget
// ---------------------------------------------------------------------------

final scadenzeDataProvider = FutureProvider.autoDispose
    .family<ScadenzeData, String>((ref, casaId) async {
      if (casaId.isEmpty) throw Exception('Nessuna casa selezionata');

      final results = await Future.wait([
        ApiProvider.turni.list(casaId),
        ApiProvider.spese.list(casaId),
        ApiProvider.scadenze.list(casaId),
      ]);

      final turni = (results[0] as List<Turno>)
          .where((t) => t.dataProssimaPulizia != null)
          .toList();

      final spese = (results[1] as List<Spesa>)
          .where((s) => s.dataScadenza != null)
          .toList();

      final scadenze = results[2] as List<Scadenza>;

      final idScadenzeConSpesa = spese
          .map((s) => s.idScadenza)
          .whereType<String>()
          .toSet();

      final items = <ScadenzaItem>[
        for (final t in turni) _turnoToItem(t),
        for (final s in spese) _spesaToItem(s),
        for (final sc in scadenze)
          if (!idScadenzeConSpesa.contains(sc.id)) _scadenzaToItem(sc),
      ]..sort((a, b) => a.sortDate.compareTo(b.sortDate));

      final today = _normDate(DateTime.now());
      return ScadenzeData(
        inScadenza: items
            .where((i) => !_normDate(i.sortDate).isAfter(today))
            .toList(),
        prossime: items
            .where((i) => _normDate(i.sortDate).isAfter(today))
            .toList(),
      );
    });

ScadenzaItem _turnoToItem(Turno t) {
  final date = t.dataProssimaPulizia!;
  return ScadenzaItem(
    title: t.titolo,
    subtitle: t.assegnatarioNome.isNotEmpty
        ? 'Assegnato a ${t.assegnatarioNome}'
        : 'Nessun assegnatario',
    date: _fmt(date),
    badgeText: _badge(date),
    tipo: ScadenzaTipo.turno,
    sortDate: date,
    turno: t,
  );
}

ScadenzaItem _spesaToItem(Spesa s) {
  final date = s.dataScadenza!;
  return ScadenzaItem(
    title: s.descrizione,
    subtitle: '€ ${s.importo.toStringAsFixed(2)}',
    date: _fmt(date),
    badgeText: _badge(date),
    tipo: ScadenzaTipo.spesa,
    sortDate: date,
    frequenza: s.isRicorrente ? 'Ricorrente' : 'Non ripetere',
    spesa: s,
  );
}

ScadenzaItem _scadenzaToItem(Scadenza sc) {
  final date = sc.dataScadenza;
  return ScadenzaItem(
    title: sc.nome,
    subtitle: sc.descrizione,
    date: _fmt(date),
    badgeText: _badge(date),
    tipo: ScadenzaTipo.scadenza,
    sortDate: date,
    frequenza: _frequenzaFromCadenza(sc.isRicorrente, sc.cadenzaGiorni),
    scadenzaObj: sc,
  );
}

String _frequenzaFromCadenza(bool isRicorrente, int? cadenzaGiorni) {
  if (!isRicorrente) return 'Non ripetere';
  switch (cadenzaGiorni) {
    case 7:
      return 'Settimanale';
    case 30:
      return 'Mensile';
    case 365:
      return 'Annuale';
    default:
      return 'Non ripetere';
  }
}

DateTime _normDate(DateTime d) => DateTime(d.year, d.month, d.day);

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _badge(DateTime date) {
  final today = _normDate(DateTime.now());
  final norm = _normDate(date);
  final diff = norm.difference(today).inDays;
  if (diff == 0) return 'Oggi';
  if (diff == -1) return 'Ieri';
  if (diff < 0) return '${-diff} gg fa';
  if (diff == 1) return 'Domani';
  return '$diff gg';
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

const _kFilterPrefKey = 'scadenze_active_filters';

class ListaScadenze extends ConsumerStatefulWidget {
  const ListaScadenze({super.key});

  @override
  ConsumerState<ListaScadenze> createState() => _ListaScadenzeState();
}

class _ListaScadenzeState extends ConsumerState<ListaScadenze> {
  Set<ScadenzaTipo> _activeFilters = {
    ScadenzaTipo.spesa,
    ScadenzaTipo.scadenza,
  };

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kFilterPrefKey);
    if (saved != null && mounted) {
      setState(() {
        _activeFilters = saved
            .map(
              (s) => ScadenzaTipo.values.firstWhere(
                (e) => e.name == s,
                orElse: () => ScadenzaTipo.scadenza,
              ),
            )
            .toSet();
      });
    }
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kFilterPrefKey,
      _activeFilters.map((e) => e.name).toList(),
    );
  }

  void _toggleFilter(ScadenzaTipo tipo) {
    setState(() {
      if (_activeFilters.contains(tipo)) {
        if (_activeFilters.length > 1) _activeFilters.remove(tipo);
      } else {
        _activeFilters.add(tipo);
      }
    });
    _saveFilters();
  }

  @override
  Widget build(BuildContext context) {
    final nomeCasa = ActiveCasaScope.read(context).selectedCasa?.nome ?? '';
    final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataAsync = ref.watch(scadenzeDataProvider(casaId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p7,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSizes.p5),
                const AppScreensHeader(title: 'Scadenze'),
                const SizedBox(height: AppSizes.p8),
                _Legend(activeFilters: _activeFilters, onToggle: _toggleFilter),
                const SizedBox(height: AppSizes.p12),
                Expanded(
                  child: dataAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.statusNegative,
                            size: AppSizes.p48,
                          ),
                          const SizedBox(height: AppSizes.p12),
                          Text(
                            'Errore nel caricamento',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: AppSizes.p16,
                            ),
                          ),
                          const SizedBox(height: AppSizes.p12),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(scadenzeDataProvider(casaId)),
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    ),
                    data: (data) {
                      final inScadenza = data.inScadenza
                          .where((i) => _activeFilters.contains(i.tipo))
                          .toList();
                      final prossime = data.prossime
                          .where((i) => _activeFilters.contains(i.tipo))
                          .toList();

                      if (data.inScadenza.isEmpty && data.prossime.isEmpty) {
                        return const _EmptyState();
                      }
                      if (inScadenza.isEmpty && prossime.isEmpty) {
                        return const _EmptyFilterState();
                      }

                      return RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(scadenzeDataProvider(casaId)),
                        child: ListView(
                          children: [
                            if (inScadenza.isNotEmpty) ...[
                              SectionLabel(
                                'IN SCADENZA',
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppSizes.p13,
                              ),
                              const SizedBox(height: AppSizes.p8),
                              ...inScadenza.map(
                                (s) => _ScadenzaCard(
                                  item: s,
                                  onTap: () => _navigate(s),
                                ),
                              ),
                              const SizedBox(height: AppSizes.p12),
                            ],
                            if (prossime.isNotEmpty) ...[
                              SectionLabel(
                                'PROSSIME',
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppSizes.p13,
                              ),
                              const SizedBox(height: AppSizes.p8),
                              ...prossime.map(
                                (s) => _ScadenzaCard(
                                  item: s,
                                  onTap: () => _navigate(s),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSizes.p8,
                    0,
                    AppSizes.p14,
                  ),
                  child: MainCtaButton(
                    label: 'Inserisci nuova scadenza',
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ScadenzaFormScreen.nuova(),
                        ),
                      );
                      if (mounted) {
                        ref.invalidate(scadenzeDataProvider(casaId));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/scadenze'),
      ),
    );
  }

  void _navigate(ScadenzaItem s) {
    switch (s.tipo) {
      case ScadenzaTipo.turno:
        Navigator.of(context).pushNamed(
          DettaglioTurnoAdminScreen.routeName,
          arguments: {
            'turno': s.turno!,
            'casaId': ActiveCasaScope.of(context).selectedCasaId ?? '',
          },
        );
      case ScadenzaTipo.spesa:
        Navigator.of(
          context,
        ).pushNamed(DettaglioSpesaAdminScreen.routeName, arguments: s.spesa);
      case ScadenzaTipo.scadenza:
        final activeCasa = ActiveCasaScope.of(context);
        final currentUserId = ApiProvider.client.currentUserId;
        final isCreator =
            s.scadenzaObj?.idCreatore != null &&
            s.scadenzaObj?.idCreatore == currentUserId;

        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => DettaglioScadenzaAdminScreen(
                  titolo: s.title,
                  descrizione: s.subtitle,
                  dataScadenza: s.sortDate,
                  stato: s.badgeText,
                  frequenza: s.frequenza,
                  isAdmin: activeCasa.isHomeAdmin,
                  isCreator: isCreator,
                  creatoDa: isCreator
                      ? (activeCasa.isHomeAdmin ? 'Tu (Admin)' : 'Tu')
                      : 'Altro coinquilino',
                  idScadenza: s.scadenzaObj?.id,
                  casaId: activeCasa.selectedCasaId,
                ),
              ),
            )
            .then((_) {
              if (mounted) {
                ref.invalidate(
                  scadenzeDataProvider(
                    ActiveCasaScope.read(context).selectedCasaId ?? '',
                  ),
                );
              }
            });
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ScadenzaCard extends StatelessWidget {
  const _ScadenzaCard({required this.item, required this.onTap});
  final ScadenzaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = item;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radius10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSizes.p6),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDarkMuted
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radius10),
          border: Border(
            left: BorderSide(width: AppSizes.p6, color: s.sideColor),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: AppSizes.p20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      s.subtitle,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: AppSizes.p14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text(
                      s.date,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: AppSizes.p14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                      vertical: AppSizes.p6,
                    ),
                    decoration: BoxDecoration(
                      color: s.sideColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppSizes.p6),
                    ),
                    child: Text(
                      s.badgeText,
                      style: TextStyle(
                        color: s.tipo == ScadenzaTipo.spesa
                            ? Colors.black87
                            : AppColors.textOnDark,
                        fontWeight: FontWeight.w700,
                        fontSize: AppSizes.p13,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                      vertical: AppSizes.p6,
                    ),
                    decoration: BoxDecoration(
                      color: s.sideColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.p6),
                      border: Border.all(
                        color: s.sideColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      s.tipoLabel,
                      style: TextStyle(
                        color: s.sideColor,
                        fontWeight: FontWeight.w700,
                        fontSize: AppSizes.p12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            color: AppColors.brandPrimary,
            size: AppSizes.p64,
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            'Nessuna scadenza',
            style: AppTextStyles.bodyStrong.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Turni e spese con data di scadenza\nappariranno qui.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list_off,
            color: AppColors.brandPrimary,
            size: AppSizes.p56,
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            'Nessun risultato',
            style: AppTextStyles.bodyStrong.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Attiva almeno un filtro dalla legenda.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.activeFilters, required this.onToggle});

  final Set<ScadenzaTipo> activeFilters;
  final ValueChanged<ScadenzaTipo> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list,
              color: AppColors.textMutedDark,
              size: AppSizes.p18,
            ),
            const SizedBox(width: AppSizes.p6),
            Text(
              'Filtra per',
              style: TextStyle(
                color: AppColors.textMutedDark,
                fontSize: AppSizes.p13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(
              color: _colorTurno,
              label: 'Turni',
              active: activeFilters.contains(ScadenzaTipo.turno),
              onTap: () => onToggle(ScadenzaTipo.turno),
            ),
            const SizedBox(width: AppSizes.p16),
            _LegendDot(
              color: _colorSpesa,
              label: 'Spese',
              active: activeFilters.contains(ScadenzaTipo.spesa),
              onTap: () => onToggle(ScadenzaTipo.spesa),
            ),
            const SizedBox(width: AppSizes.p16),
            _LegendDot(
              color: _colorScadenza,
              label: 'Scadenze',
              active: activeFilters.contains(ScadenzaTipo.scadenza),
              onTap: () => onToggle(ScadenzaTipo.scadenza),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final Color color;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: active ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p10,
            vertical: AppSizes.p5,
          ),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.p20),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.p10,
                height: AppSizes.p10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSizes.p5),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: AppSizes.p14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
