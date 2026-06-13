import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/scadenza.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/state/active_casa_session.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_admin.dart';
import 'package:coincasa_app/features/turni/screens/dettaglio_turno_admin.dart';
import 'dettaglio_scadenza_admin.dart';
import 'scadenza_form_screen.dart';

// ---------------------------------------------------------------------------
// Color coding — identico al calendario in dashboard
// ---------------------------------------------------------------------------
const _colorTurno = Color(0xFF3E80FF);
const _colorSpesa = Color(0xFFFFD31A);
const _colorScadenza = Color(0xFFF75C6C);

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
class _ScadenzeData {
  const _ScadenzeData({required this.inScadenza, required this.prossime});
  final List<ScadenzaItem> inScadenza;
  final List<ScadenzaItem> prossime;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class ListaScadenze extends StatefulWidget {
  const ListaScadenze({super.key});

  @override
  State<ListaScadenze> createState() => _ListaScadenzeState();
}

class _ListaScadenzeState extends State<ListaScadenze> {
  late Future<_ScadenzeData> _future;
  bool _initialized = false;
  final Set<ScadenzaTipo> _activeFilters = {
    ScadenzaTipo.turno,
    ScadenzaTipo.spesa,
    ScadenzaTipo.scadenza,
  };

  void _toggleFilter(ScadenzaTipo tipo) {
    setState(() {
      if (_activeFilters.contains(tipo)) {
        // Lascia almeno un filtro attivo
        if (_activeFilters.length > 1) _activeFilters.remove(tipo);
      } else {
        _activeFilters.add(tipo);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  Future<_ScadenzeData> _load() async {
    final activeCasa = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) throw Exception('Nessuna casa trovata');
    final casa = await ensureActiveCasaContext(
      activeCasa,
      caseUtente: caseUtente,
    );

    final results = await Future.wait([
      ApiProvider.turni.list(casa.id),
      ApiProvider.spese.list(casa.id),
      ApiProvider.scadenze.list(casa.id),
    ]);

    final turni = (results[0] as List<Turno>)
        .where((t) => t.dataProssimaPulizia != null)
        .toList();

    final spese = (results[1] as List<Spesa>)
        .where((s) => s.dataScadenza != null)
        .toList();

    final scadenze = results[2] as List<Scadenza>;

    // Scadenze collegate a una spesa vanno mostrate in giallo (come le spese)
    final idScadenzeConSpesa = spese
        .map((s) => s.idScadenza)
        .whereType<String>()
        .toSet();

    final items = <ScadenzaItem>[
      for (final t in turni) _turnoToItem(t),
      for (final s in spese) _spesaToItem(s),
      // Salta le scadenze già rappresentate dalla loro spesa collegata
      for (final sc in scadenze)
        if (!idScadenzeConSpesa.contains(sc.id)) _scadenzaToItem(sc),
    ]..sort((a, b) => a.sortDate.compareTo(b.sortDate));

    final today = _normDate(DateTime.now());
    return _ScadenzeData(
      inScadenza: items
          .where((i) => !_normDate(i.sortDate).isAfter(today))
          .toList(),
      prossime: items
          .where((i) => _normDate(i.sortDate).isAfter(today))
          .toList(),
    );
  }

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

  static String _frequenzaFromCadenza(bool isRicorrente, int? cadenzaGiorni) {
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

  void _refresh() {
    setState(() {
      _initialized = false;
    });
    // Triggering didChangeDependencies indirectly via setState isn't reliable,
    // so we reload the future directly.
    setState(() {
      _initialized = true;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nomeCasa = ActiveCasaScope.read(context).selectedCasa?.nome ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Text(
                        nomeCasa,
                        style: const TextStyle(
                          color: Color(0xFF8C8CA0),
                          fontSize: 20,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scadenze',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenTitleStrong.copyWith(
                          color: AppColors.brandAccent,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _Legend(activeFilters: _activeFilters, onToggle: _toggleFilter),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<_ScadenzeData>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFF75C6C),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Errore nel caricamento',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _refresh,
                                child: const Text('Riprova'),
                              ),
                            ],
                          ),
                        );
                      }

                      final data = snap.data!;
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
                        onRefresh: () async => _refresh(),
                        child: ListView(
                          children: [
                            if (inScadenza.isNotEmpty) ...[
                              const _SectionHeader(label: 'IN SCADENZA'),
                              const SizedBox(height: 8),
                              ...inScadenza.map(
                                (s) => _ScadenzaCard(
                                  item: s,
                                  onTap: () => _navigate(s),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (prossime.isNotEmpty) ...[
                              const _SectionHeader(label: 'PROSSIME'),
                              const SizedBox(height: 8),
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
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
                  child: MainCtaButton(
                    label: 'Inserisci nuova scadenza',
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ScadenzaFormScreen.nuova(),
                        ),
                      );
                      _refresh();
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
          arguments: s.turno!.id,
        );
      case ScadenzaTipo.spesa:
        Navigator.of(
          context,
        ).pushNamed(DettaglioSpesaAdminScreen.routeName, arguments: s.spesa);
      case ScadenzaTipo.scadenza:
        final activeCasa = ActiveCasaScope.of(context);
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
                  idScadenza: s.scadenzaObj?.id,
                  casaId: activeCasa.selectedCasaId,
                ),
              ),
            )
            .then((_) => _refresh());
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  static DateTime _normDate(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _badge(DateTime date) {
    final today = _normDate(DateTime.now());
    final norm = _normDate(date);
    final diff = norm.difference(today).inDays;
    if (diff == 0) return 'Oggi';
    if (diff == -1) return 'Ieri';
    if (diff < 0) return '${-diff} gg fa';
    if (diff == 1) return 'Domani';
    return '$diff gg';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFD8D5D5),
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ScadenzaCard extends StatelessWidget {
  const _ScadenzaCard({required this.item, required this.onTap});
  final ScadenzaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = item;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF16203C),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(width: 6, color: s.sideColor)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: const TextStyle(
                        color: Color(0xFFD8D5D5),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.subtitle,
                      style: const TextStyle(
                        color: Color(0xFFD8D5D5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.date,
                      style: const TextStyle(
                        color: Color(0xFFD8D5D5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: s.sideColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.badgeText,
                      style: TextStyle(
                        color: s.tipo == ScadenzaTipo.spesa
                            ? Colors.black87
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: s.sideColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: s.sideColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      s.tipoLabel,
                      style: TextStyle(
                        color: s.sideColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
        children: const [
          Icon(Icons.event_available, color: Color(0xFF5A2BBF), size: 64),
          SizedBox(height: 16),
          Text(
            'Nessuna scadenza',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Turni e spese con data di scadenza\nappariranno qui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(
          color: _colorTurno,
          label: 'Turni',
          active: activeFilters.contains(ScadenzaTipo.turno),
          onTap: () => onToggle(ScadenzaTipo.turno),
        ),
        const SizedBox(width: 16),
        _LegendDot(
          color: _colorSpesa,
          label: 'Spese',
          active: activeFilters.contains(ScadenzaTipo.spesa),
          onTap: () => onToggle(ScadenzaTipo.spesa),
        ),
        const SizedBox(width: 16),
        _LegendDot(
          color: _colorScadenza,
          label: 'Scadenze',
          active: activeFilters.contains(ScadenzaTipo.scadenza),
          onTap: () => onToggle(ScadenzaTipo.scadenza),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? color : const Color(0xFFB0AACC),
                  fontSize: 14,
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

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_off, color: Color(0xFF5A2BBF), size: 56),
          SizedBox(height: 16),
          Text(
            'Nessun risultato',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Attiva almeno un filtro dalla legenda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
