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
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/turni/screens/dettaglio_turno_admin.dart';
import 'package:coincasa_app/features/turni/screens/turno_create_screen.dart';

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
    final calendarTurni = turniAsync.maybeWhen(
      data: (turni) => turni,
      orElse: () => const <Turno>[],
    );

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
                    AppSizes.p10,
                    AppSizes.p16,
                    AppSizes.p24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Turni',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.screenTitleStrong.copyWith(
                          color: AppColors.brandAccent,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
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
                      Text(
                        'Turni assegnati',
                        style: AppTextStyles.screenTitleStrong.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p8),
                      turniAsync.when(
                        loading: () => const _TurniStatePanel(
                          message: 'Caricamento turni...',
                        ),
                        error: (_, _) => const _TurniStatePanel(
                          message: 'Impossibile caricare i turni.',
                        ),
                        data: (turni) => turni.isEmpty
                            ? const _TurniStatePanel(
                                message:
                                    'Non ci sono turni per adesso...\nCreane subito uno nuovo!',
                              )
                            : _AssignedTurniCard(
                                turni: turni,
                                onTurnoTap: (turno) =>
                                    Navigator.of(context).pushNamed(
                                      DettaglioTurnoAdminScreen.routeName,
                                      arguments: turno.id,
                                    ),
                              ),
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
  static const _weekdaysShort = ['Lu', 'Ma', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
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
                    marker: day.marker,
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
                          marker: day.marker,
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
                    const SizedBox(width: AppSizes.p18),
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
        marker: _markerForDate(date, widget.turni),
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

  static Color? _markerForDate(DateTime date, List<Turno> turni) {
    for (final turno in turni) {
      if (turno.assegnatarioId.isEmpty) {
        continue;
      }
      final turnoDate = turno.dataProssimaPulizia;
      if (turnoDate != null && _isSameDate(turnoDate, date)) {
        return _colorForAssignee(turno.assegnatarioNome);
      }
    }
    return null;
  }

  static List<_CalendarLegendItem> _legendItems(List<Turno> turni) {
    final items = <String, Color>{};
    for (final turno in turni) {
      if (turno.assegnatarioId.isEmpty) {
        continue;
      }
      final label = resolveUserInitials(displayName: turno.assegnatarioNome);
      if (label != '?' && label != '??' && !items.containsKey(label)) {
        items[label] = _colorForAssignee(turno.assegnatarioNome);
      }
      if (items.length == 3) {
        break;
      }
    }
    return items.entries
        .map(
          (entry) => _CalendarLegendItem(label: entry.key, color: entry.value),
        )
        .toList(growable: false);
  }

  static Color _colorForAssignee(String name) {
    final colors = const [
      Color(0xFF20F545),
      Color(0xFFFF941F),
      Color(0xFFD25BFF),
      Color(0xFF4FC3F7),
    ];
    final hash = name.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return colors[hash % colors.length];
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
    required this.marker,
  });

  final DateTime date;
  final bool inFocusedMonth;
  final bool isToday;
  final Color? marker;
}

class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({
    required this.day,
    required this.selected,
    required this.marker,
  });

  final String day;
  final bool selected;
  final Color? marker;

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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: marker ?? AppColors.transparent,
          ),
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
    required this.marker,
  });

  final String day;
  final bool muted;
  final bool selected;
  final Color? marker;

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
        Container(
          width: AppSizes.p8,
          height: AppSizes.p8,
          decoration: BoxDecoration(
            color: marker ?? AppColors.transparent,
            shape: BoxShape.circle,
          ),
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
          width: AppSizes.p18,
          height: AppSizes.p18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.p5),
        Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textMutedLight,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AssignedTurniCard extends StatelessWidget {
  const _AssignedTurniCard({required this.turni, required this.onTurnoTap});

  final List<Turno> turni;
  final ValueChanged<Turno> onTurnoTap;

  static const _whenColors = [
    Color(0xFF2E8641),
    Color(0xFF835C2F),
    Color(0xFF65347C),
    Color(0xFF286D76),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF272746),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: AppSizes.p10,
            offset: Offset(0, AppSizes.p5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p14,
        vertical: AppSizes.p14,
      ),
      child: Column(
        children: List.generate(turni.length, (index) {
          final turno = turni[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == turni.length - 1 ? 0 : AppSizes.p18,
            ),
            child: _AssignedTurnoRow(
              userId: turno.assegnatarioId,
              displayName: turno.assegnatarioNome,
              task: turno.titolo,
              when: _whenLabel(turno.dataProssimaPulizia),
              whenColor: _whenColors[index % _whenColors.length],
              onTap: () => onTurnoTap(turno),
            ),
          );
        }),
      ),
    );
  }

  static String _whenLabel(DateTime? date) {
    if (date == null) {
      return 'turno';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final delta = target.difference(today).inDays;
    if (delta == 0) {
      return 'oggi';
    }
    if (delta == 1) {
      return 'domani';
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
    return '${target.day}/${target.month}';
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

class _AssignedTurnoRow extends StatelessWidget {
  const _AssignedTurnoRow({
    required this.userId,
    required this.displayName,
    required this.task,
    required this.when,
    required this.whenColor,
    this.onTap,
  });

  final String? userId;
  final String displayName;
  final String task;
  final String when;
  final Color whenColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p2),
        child: Row(
          children: [
            UserAvatar(
              radius: AppSizes.p23,
              userId: userId?.isNotEmpty == true ? userId : null,
              fullName: displayName.trim().isNotEmpty ? displayName : null,
              fallback: '?',
            ),
            const SizedBox(width: AppSizes.p24),
            Expanded(
              child: Text(
                task,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: const Color(0xFFD6D7E8),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 82),
              height: AppSizes.p32,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10),
              decoration: BoxDecoration(
                color: whenColor,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
              child: Text(
                when,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
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
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.statusInfo,
        disabledBackgroundColor: AppColors.statusInfo,
        foregroundColor: AppColors.textOnDark,
        disabledForegroundColor: AppColors.textOnDark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p24,
          vertical: AppSizes.p12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.p18),
          side: const BorderSide(color: AppColors.textMutedLight, width: 2),
        ),
        elevation: AppSizes.p6,
      ),
      child: Text(
        'Inserisci turno',
        style: AppTextStyles.buttonCompact.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
