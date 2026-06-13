import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/route_observer.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/turni/screens/dettaglio_turno_admin.dart';
import 'package:coincasa_app/features/turni/screens/turno_create_screen.dart';

final _me = ApiProvider.client;

final _listaTurniCasaProvider = FutureProvider.autoDispose
    .family<Casa?, String?>((ref, selectedCasaId) async {
      final caseUtente = await ApiProvider.casa.list();
      if (caseUtente.isEmpty) {
        return null;
      }
      if (selectedCasaId != null && selectedCasaId.isNotEmpty) {
        for (final casa in caseUtente) {
          if (casa.id == selectedCasaId) {
            return casa;
          }
        }
      }
      return caseUtente.first;
    });

final _listaTurniProvider = FutureProvider.autoDispose
    .family<List<Turno>, String?>((ref, casaId) {
      if (casaId == null || casaId.isEmpty) {
        return const [];
      }
      return ApiProvider.turni.list(casaId);
    });

class ListaTurniScreen extends ConsumerStatefulWidget {
  const ListaTurniScreen({super.key, this.onInserisciTurno});

  final VoidCallback? onInserisciTurno;

  @override
  ConsumerState<ListaTurniScreen> createState() => _ListaTurniScreenState();
}

class _ListaTurniScreenState extends ConsumerState<ListaTurniScreen>
    with RouteAware {
  /// Cache statica: sopravvive a pushReplacementNamed e autoDispose dei provider.
  static List<Turno>? _cachedTurni;

  final Set<String> _completingIds = {};

  Future<void> _completaTurno(String casaId, String turnoId) async {
    setState(() {
      _completingIds.add(turnoId);
    });
    try {
      await ApiProvider.turni.completa(casaId, turnoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turno completato con successo!')),
        );
        _refreshTurni();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile completare il turno. Riprova.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _completingIds.remove(turnoId);
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    _refreshTurni();
  }

  @override
  void didPopNext() {
    _refreshTurni();
  }

  void _refreshTurni() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.invalidate(_listaTurniCasaProvider);
      ref.invalidate(_listaTurniProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.of(context);
    final casaAsync = ref.watch(
      _listaTurniCasaProvider(activeCasaController.selectedCasaId),
    );
    final turniAsync = casaAsync.when(
      data: (casa) => ref.watch(_listaTurniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Turno>>.loading(),
      error: (error, stackTrace) =>
          AsyncValue<List<Turno>>.error(error, stackTrace),
    );
    // Aggiorna la cache ogni volta che arrivano dati freschi.
    turniAsync.whenData((t) => _cachedTurni = t);

    // Usa la cache come fallback durante il caricamento.
    final calendarTurni =
        turniAsync.maybeWhen(data: (t) => t, orElse: () => null) ??
        _cachedTurni ??
        const <Turno>[];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/turni'),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.p16,
                    0,
                    AppSizes.p16,
                    AppSizes.p24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.p12),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                ActiveCasaScope.read(
                                      context,
                                    ).selectedCasa?.nome ??
                                    '',
                                style: const TextStyle(
                                  color: Color(0xFF8C8CA0),
                                  fontSize: 20,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Turni',
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
                      ),
                      const SizedBox(height: AppSizes.p14),
                      Text(
                        'Calendario',
                        style: AppTextStyles.screenTitleStrong.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p8),
                      _TurniCalendarCard(turni: calendarTurni),
                      const SizedBox(height: AppSizes.p35),
                      Builder(
                        builder: (context) {
                          final effectiveTurni =
                              turniAsync.maybeWhen(
                                data: (t) => t,
                                orElse: () => null,
                              ) ??
                              _cachedTurni;

                          if (effectiveTurni != null) {
                            if (effectiveTurni.isEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Turni assegnati',
                                    style: AppTextStyles.screenTitleStrong
                                        .copyWith(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: AppSizes.p8),
                                  const _TurniStatePanel(
                                    message:
                                        'Non ci sono turni per adesso...\nCreane subito uno nuovo!',
                                  ),
                                ],
                              );
                            }

                            final now = DateTime.now();
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );

                            final turniScaduti =
                                effectiveTurni.where((t) {
                                  if (t.completato) return false;
                                  final date = t.dataProssimaPulizia;
                                  if (date == null) return false;
                                  final dateOnly = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                  );
                                  return dateOnly.isBefore(today) ||
                                      dateOnly.isAtSameMomentAs(today);
                                }).toList()..sort((a, b) {
                                  final aDate = a.dataProssimaPulizia;
                                  final bDate = b.dataProssimaPulizia;
                                  if (aDate == null && bDate == null) return 0;
                                  if (aDate == null) return 1;
                                  if (bDate == null) return -1;
                                  return aDate.compareTo(bDate);
                                });

                            final turniAssegnati =
                                effectiveTurni.where((t) {
                                  if (t.completato) return false;
                                  final date = t.dataProssimaPulizia;
                                  if (date == null) return true;
                                  final dateOnly = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                  );
                                  return dateOnly.isAfter(today);
                                }).toList()..sort((a, b) {
                                  final aDate = a.dataProssimaPulizia;
                                  final bDate = b.dataProssimaPulizia;
                                  if (aDate == null && bDate == null) return 0;
                                  if (aDate == null) return 1;
                                  if (bDate == null) return -1;
                                  return aDate.compareTo(bDate);
                                });

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (turniScaduti.isNotEmpty) ...[
                                  Text(
                                    'Turni scaduti',
                                    style: AppTextStyles.screenTitleStrong
                                        .copyWith(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.statusNegative,
                                        ),
                                  ),
                                  const SizedBox(height: AppSizes.p8),
                                  _ExpiredTurniCard(
                                    turni: turniScaduti,
                                    onTurnoTap: (turno) =>
                                        Navigator.of(context).pushNamed(
                                          DettaglioTurnoAdminScreen.routeName,
                                          arguments: turno.id,
                                        ),
                                    currentUserId: _me.currentUserId,
                                    casaId: casaAsync.value?.id,
                                    completingIds: _completingIds,
                                    onCompleta: _completaTurno,
                                  ),
                                  const SizedBox(height: AppSizes.p35),
                                ],
                                Text(
                                  'Turni assegnati',
                                  style: AppTextStyles.screenTitleStrong
                                      .copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: AppSizes.p8),
                                if (turniAssegnati.isEmpty)
                                  const _TurniStatePanel(
                                    message: 'Non ci sono turni assegnati.',
                                  )
                                else
                                  _AssignedTurniCard(
                                    turni: turniAssegnati,
                                    onTurnoTap: (turno) =>
                                        Navigator.of(context).pushNamed(
                                          DettaglioTurnoAdminScreen.routeName,
                                          arguments: turno.id,
                                        ),
                                    currentUserId: _me.currentUserId,
                                    casaId: casaAsync.value?.id,
                                    completingIds: _completingIds,
                                    onCompleta: _completaTurno,
                                  ),
                              ],
                            );
                          }

                          if (turniAsync.hasError) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Turni assegnati',
                                  style: AppTextStyles.screenTitleStrong
                                      .copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: AppSizes.p8),
                                const _TurniStatePanel(
                                  message: 'Impossibile caricare i turni.',
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Turni assegnati',
                                style: AppTextStyles.screenTitleStrong.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSizes.p8),
                              const _TurniStatePanel(
                                message: 'Caricamento turni...',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.p40),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p10,
                  AppSizes.p0,
                  AppSizes.p10,
                  AppSizes.p14,
                ),
                child: _InsertTurnoButton(
                  onPressed:
                      widget.onInserisciTurno ??
                      () => Navigator.of(
                        context,
                      ).pushNamed(TurnoCreateScreen.routeName),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurniCalendarCard extends StatefulWidget {
  const _TurniCalendarCard({required this.turni});

  final List<Turno> turni;

  @override
  State<_TurniCalendarCard> createState() => _TurniCalendarCardState();
}

class _TurniCalendarCardState extends State<_TurniCalendarCard> {
  static const _weekdaysShort = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
  static const _weekdaysTiny = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
  static const _monthNames = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];

  late DateTime _focusedMonth;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final gridDays = _buildGridDays(_focusedMonth);
    final visibleWeek = _currentWeek(gridDays);
    final legend = _legendItems(widget.turni);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF20284D),
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p8,
              offset: Offset(0, AppSizes.p5),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p16,
          AppSizes.p14,
          AppSizes.p16,
          AppSizes.p12,
        ),
        child: Column(
          children: [
            if (_expanded)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.brandAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 34,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.brandAccent,
                    ),
                  ),
                  IconButton(
                    iconSize: 34,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.brandAccent,
                    ),
                  ),
                ],
              ),
            if (_expanded) const SizedBox(height: AppSizes.p12),
            Row(
              children: (_expanded ? _weekdaysTiny : _weekdaysShort)
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textMutedLight,
                          fontSize: _expanded ? 18 : 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSizes.p10),
            if (_expanded)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gridDays.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.82,
                  mainAxisSpacing: AppSizes.p8,
                  crossAxisSpacing: AppSizes.p4,
                ),
                itemBuilder: (context, index) {
                  final day = gridDays[index];
                  return _CalendarDayCell(
                    day: '${day.date.day}',
                    muted: !day.inFocusedMonth,
                    selected: day.isToday,
                    markers: day.markers,
                  );
                },
              )
            else
              Row(
                children: visibleWeek
                    .map(
                      (day) => Expanded(
                        child: _WeekDayCell(
                          day: '${day.date.day}',
                          selected: day.isToday,
                          markers: day.markers,
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: AppSizes.p14),
            Row(
              children: [
                ...legend.expand(
                  (item) => [
                    _CalendarLegendDot(color: item.color, label: item.label),
                    const SizedBox(width: AppSizes.p12),
                  ],
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                  child: Icon(
                    _expanded
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: AppColors.brandAccent,
                    size: 34,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_CalendarGridDay> _buildGridDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final mondayIndex = firstOfMonth.weekday - 1;
    final start = firstOfMonth.subtract(Duration(days: mondayIndex));

    return List.generate(42, (index) {
      final date = start.add(Duration(days: index));
      return _CalendarGridDay(
        date: date,
        inFocusedMonth: date.month == month.month,
        isToday: _isSameDate(date, DateTime.now()),
        markers: _markersForDate(date, widget.turni),
      );
    });
  }

  List<_CalendarGridDay> _currentWeek(List<_CalendarGridDay> days) {
    final todayIndex = days.indexWhere((day) => day.isToday);
    if (todayIndex >= 0) {
      final weekStart = (todayIndex ~/ 7) * 7;
      return days.sublist(weekStart, weekStart + 7);
    }
    return days.sublist(0, 7);
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<Color> _markersForDate(DateTime date, List<Turno> turni) {
    final colors = <Color>[];
    for (final turno in turni) {
      if (turno.assegnatarioId.isEmpty) continue;
      final turnoDate = turno.dataProssimaPulizia;
      if (turnoDate != null && _isSameDate(turnoDate, date)) {
        colors.add(userAvatarColorsForSeed(turno.assegnatarioId).background);
        if (colors.length == 4) break;
      }
    }
    return colors;
  }

  static List<_CalendarLegendItem> _legendItems(List<Turno> turni) {
    final items = <String, _CalendarLegendItem>{};
    for (final turno in turni) {
      if (turno.assegnatarioId.isEmpty) continue;
      if (items.containsKey(turno.assegnatarioId)) continue;
      final label = resolveUserInitials(displayName: turno.assegnatarioNome);
      if (label != '?' && label != '??') {
        items[turno.assegnatarioId] = _CalendarLegendItem(
          label: label,
          color: userAvatarColorsForSeed(turno.assegnatarioId).background,
        );
      }
      if (items.length == 3) break;
    }
    return items.values.toList(growable: false);
  }
}

class _CalendarLegendItem {
  const _CalendarLegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

class _CalendarGridDay {
  const _CalendarGridDay({
    required this.date,
    required this.inFocusedMonth,
    required this.isToday,
    required this.markers,
  });

  final DateTime date;
  final bool inFocusedMonth;
  final bool isToday;
  final List<Color> markers;
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({
    required this.day,
    required this.selected,
    required this.markers,
  });

  final String day;
  final bool selected;
  final List<Color> markers;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandAccent.withValues(alpha: 0.32)
                : null,
            borderRadius: BorderRadius.circular(AppSizes.radius8),
          ),
          child: Text(
            day,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textOnDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (markers.isEmpty)
              const SizedBox(width: 10, height: 10)
            else
              ...markers.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(left: e.key == 0 ? 0 : 2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: e.value,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.muted,
    required this.selected,
    required this.markers,
  });

  final String day;
  final bool muted;
  final bool selected;
  final List<Color> markers;

  @override
  Widget build(BuildContext context) {
    final textColor = muted ? const Color(0xFF7D8192) : AppColors.textOnDark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: selected ? 36 : AppSizes.p32,
          height: selected ? 36 : AppSizes.p32,
          alignment: Alignment.center,
          decoration: selected
              ? const BoxDecoration(
                  color: Color(0xFFD25BFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x99D25BFF),
                      blurRadius: AppSizes.p10,
                    ),
                  ],
                )
              : null,
          child: Text(
            day,
            style: AppTextStyles.bodyStrong.copyWith(
              color: selected ? AppColors.textOnDark : textColor,
              fontSize: 19,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (markers.isEmpty)
              const SizedBox(width: 8, height: 8)
            else
              ...markers.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(left: e.key == 0 ? 0 : 2),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: e.value,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.p5),
        Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textMutedLight,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _formatTurnoDateLabel(DateTime? date) {
  if (date == null) {
    return 'turno';
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);

  final deltaMs = target.millisecondsSinceEpoch - today.millisecondsSinceEpoch;
  final delta = (deltaMs / 86400000).round();

  if (delta == 0) {
    return 'oggi';
  }
  if (delta == 1) {
    return 'domani';
  }
  if (delta == -1) {
    return 'ieri';
  }
  if (delta == -2) {
    return "l'altro ieri";
  }
  if (delta > 1 && delta < 7) {
    return const [
      'lunedi',
      'martedi',
      'mercoledi',
      'giovedi',
      'venerdi',
      'sabato',
      'domenica',
    ][target.weekday - 1];
  }
  return '${target.day.toString().padLeft(2, '0')}/${target.month.toString().padLeft(2, '0')}';
}

class _AssignedTurniCard extends StatelessWidget {
  const _AssignedTurniCard({
    required this.turni,
    required this.onTurnoTap,
    required this.currentUserId,
    required this.casaId,
    required this.completingIds,
    required this.onCompleta,
  });

  final List<Turno> turni;
  final ValueChanged<Turno> onTurnoTap;
  final String? currentUserId;
  final String? casaId;
  final Set<String> completingIds;
  final void Function(String casaId, String turnoId) onCompleta;

  static const _whenColors = [
    Color(0xFF2E8641),
    Color(0xFF835C2F),
    Color(0xFF65347C),
    Color(0xFF286D76),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(turni.length, (index) {
        final turno = turni[index];
        final isCurrentAssignee =
            currentUserId != null &&
            currentUserId!.isNotEmpty &&
            turno.assegnatarioId == currentUserId;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == turni.length - 1 ? 0 : AppSizes.p10,
          ),
          child: _TurnoCard(
            userId: turno.assegnatarioId,
            displayName: turno.assegnatarioNome,
            task: turno.titolo,
            when: _formatTurnoDateLabel(turno.dataProssimaPulizia),
            whenColor: _whenColors[index % _whenColors.length],
            isCurrentAssignee: isCurrentAssignee,
            isCompleting: completingIds.contains(turno.id),
            onCompletaTap: () {
              if (casaId != null) onCompleta(casaId!, turno.id);
            },
            isExpired: false,
            onTap: () => onTurnoTap(turno),
          ),
        );
      }),
    );
  }
}

class _ExpiredTurniCard extends StatelessWidget {
  const _ExpiredTurniCard({
    required this.turni,
    required this.onTurnoTap,
    required this.currentUserId,
    required this.casaId,
    required this.completingIds,
    required this.onCompleta,
  });

  final List<Turno> turni;
  final ValueChanged<Turno> onTurnoTap;
  final String? currentUserId;
  final String? casaId;
  final Set<String> completingIds;
  final void Function(String casaId, String turnoId) onCompleta;

  static const _whenColors = [
    Color(0xFF2E8641),
    Color(0xFF835C2F),
    Color(0xFF65347C),
    Color(0xFF286D76),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(turni.length, (index) {
        final turno = turni[index];
        final isCurrentAssignee =
            currentUserId != null &&
            currentUserId!.isNotEmpty &&
            turno.assegnatarioId == currentUserId;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == turni.length - 1 ? 0 : AppSizes.p10,
          ),
          child: _TurnoCard(
            userId: turno.assegnatarioId,
            displayName: turno.assegnatarioNome,
            task: turno.titolo,
            when: _formatTurnoDateLabel(turno.dataProssimaPulizia),
            whenColor: _whenColors[index % _whenColors.length],
            isCurrentAssignee: isCurrentAssignee,
            isCompleting: completingIds.contains(turno.id),
            onCompletaTap: () {
              if (casaId != null) onCompleta(casaId!, turno.id);
            },
            isExpired: true,
            onTap: () => onTurnoTap(turno),
          ),
        );
      }),
    );
  }
}

class _TurniStatePanel extends StatelessWidget {
  const _TurniStatePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: AppSizes.p8,
            offset: Offset(0, AppSizes.p5),
          ),
        ],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.statusPositive,
          fontSize: 22,
          height: 1.16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TurnoCard extends StatelessWidget {
  const _TurnoCard({
    required this.userId,
    required this.displayName,
    required this.task,
    required this.when,
    required this.whenColor,
    required this.isCurrentAssignee,
    required this.isCompleting,
    required this.onCompletaTap,
    required this.isExpired,
    this.onTap,
  });

  final String? userId;
  final String displayName;
  final String task;
  final String when;
  final Color whenColor;
  final bool isCurrentAssignee;
  final bool isCompleting;
  final VoidCallback onCompletaTap;
  final bool isExpired;
  final VoidCallback? onTap;

  static const _cardRadius = Radius.circular(AppSizes.radius12);
  static const _cardBorderRadius = BorderRadius.all(_cardRadius);

  @override
  Widget build(BuildContext context) {
    final showCompleta = isCurrentAssignee && isExpired;
    final taskColor = isExpired
        ? AppColors.statusNegative
        : const Color(0xFFD6D7E8);

    return ClipRRect(
      borderRadius: _cardBorderRadius,
      child: Material(
        color: const Color(0xFF272746),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Riga principale ───────────────────────────────────────────
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSizes.p14,
                  AppSizes.p14,
                  AppSizes.p14,
                  showCompleta ? AppSizes.p12 : AppSizes.p14,
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      radius: AppSizes.p23,
                      userId: userId?.isNotEmpty == true ? userId : null,
                      username: displayName.trim().isNotEmpty
                          ? displayName
                          : null,
                      fallback: '?',
                    ),
                    const SizedBox(width: AppSizes.p14),
                    Expanded(
                      child: Text(
                        task,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: taskColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p10),
                    // Badge data — inline, peso secondario
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p10,
                        vertical: AppSizes.p5,
                      ),
                      decoration: BoxDecoration(
                        color: whenColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                      ),
                      child: Text(
                        when,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Barra "Completa" ──────────────────────────────────────────
            if (showCompleta) ...[
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dividerOnDark,
              ),
              _CompletaBar(isCompleting: isCompleting, onTap: onCompletaTap),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletaBar extends StatelessWidget {
  const _CompletaBar({required this.isCompleting, required this.onTap});

  final bool isCompleting;
  final VoidCallback onTap;

  static const _bottomRadius = BorderRadius.only(
    bottomLeft: Radius.circular(AppSizes.radius12),
    bottomRight: Radius.circular(AppSizes.radius12),
  );

  @override
  Widget build(BuildContext context) {
    if (isCompleting) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.statusSuccess,
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: _bottomRadius,
      child: Container(
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFF1B5E20),
          borderRadius: _bottomRadius,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_rounded,
              color: AppColors.textOnDark,
              size: 18,
            ),
            const SizedBox(width: AppSizes.p6),
            Text(
              'Completa',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textOnDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsertTurnoButton extends StatelessWidget {
  const _InsertTurnoButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return MainCtaButton(label: 'Inserisci nuovo turno', onPressed: onPressed);
  }
}
