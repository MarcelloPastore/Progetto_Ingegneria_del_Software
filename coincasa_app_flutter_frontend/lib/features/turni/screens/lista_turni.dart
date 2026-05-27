import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/turni/screens/dettaglio_turno_admin.dart';
import 'package:coincasa_app/features/turni/screens/turno_create_screen.dart';

class ListaTurniScreen extends ConsumerWidget {
  const ListaTurniScreen({super.key, this.onInserisciTurno});

  final VoidCallback? onInserisciTurno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
                    const _TurniCalendarCard(),
                    const SizedBox(height: AppSizes.p35),
                    Text(
                      'Turni assegnati',
                      style: AppTextStyles.screenTitleStrong.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p8),
                    _AssignedTurniCard(
                      onBagnoTap: () => Navigator.of(
                        context,
                      ).pushNamed(DettaglioTurnoAdminScreen.routeName),
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
                    onInserisciTurno ??
                    () => Navigator.of(
                      context,
                    ).pushNamed(TurnoCreateScreen.routeName),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurniCalendarCard extends StatefulWidget {
  const _TurniCalendarCard();

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
                const _CalendarLegendDot(color: Color(0xFF20F545), label: 'FP'),
                const SizedBox(width: AppSizes.p18),
                const _CalendarLegendDot(color: Color(0xFFFF941F), label: 'MR'),
                const SizedBox(width: AppSizes.p18),
                const _CalendarLegendDot(color: Color(0xFFD25BFF), label: 'AL'),
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
        marker: _markerForDate(date),
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

  static Color? _markerForDate(DateTime date) {
    if (date.weekday == DateTime.monday) {
      return const Color(0xFF20F545);
    }
    if (date.weekday == DateTime.tuesday) {
      return const Color(0xFFFF941F);
    }
    if (date.weekday == DateTime.saturday) {
      return const Color(0xFFD25BFF);
    }

    return null;
  }
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
  const _AssignedTurniCard({required this.onBagnoTap});

  final VoidCallback onBagnoTap;

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
        children: [
          _AssignedTurnoRow(
            initials: 'FP',
            task: 'Bagno',
            when: 'oggi',
            avatarColor: const Color(0xFF2F8F46),
            whenColor: const Color(0xFF2E8641),
            textColor: const Color(0xFF66FF7B),
            onTap: onBagnoTap,
          ),
          const SizedBox(height: AppSizes.p18),
          const _AssignedTurnoRow(
            initials: 'MR',
            task: 'Ingresso',
            when: 'domani',
            avatarColor: Color(0xFF78542A),
            whenColor: Color(0xFF835C2F),
            textColor: Color(0xFFFFA83D),
          ),
          SizedBox(height: AppSizes.p18),
          _AssignedTurnoRow(
            initials: 'AL',
            task: 'Soggiorno',
            when: 'sabato',
            avatarColor: Color(0xFF60347D),
            whenColor: Color(0xFF65347C),
            textColor: Color(0xFFE889FF),
          ),
        ],
      ),
    );
  }
}

class _AssignedTurnoRow extends StatelessWidget {
  const _AssignedTurnoRow({
    required this.initials,
    required this.task,
    required this.when,
    required this.avatarColor,
    required this.whenColor,
    required this.textColor,
    this.onTap,
  });

  final String initials;
  final String task;
  final String when;
  final Color avatarColor;
  final Color whenColor;
  final Color textColor;
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
            CircleAvatar(
              radius: AppSizes.p23,
              backgroundColor: avatarColor,
              child: Text(
                initials,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
                  color: textColor,
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
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
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
