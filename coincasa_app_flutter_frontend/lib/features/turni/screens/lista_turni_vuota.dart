import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/turni/screens/turno_create_screen.dart';

class ListaTurniVuotaScreen extends ConsumerWidget {
  const ListaTurniVuotaScreen({super.key, this.onInserisciTurno});

  final VoidCallback? onInserisciTurno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/turni'),
      body: SafeArea(
        child: Padding(
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
              const SizedBox(height: AppSizes.p18),
              Text(
                'Calendario',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              const _TurniCalendarCard(),
              const SizedBox(height: AppSizes.p40),
              Text(
                'Turni assegnati',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              const _EmptyTurniPanel(),
              const Spacer(),
              _InsertTurnoButton(
                onPressed:
                    onInserisciTurno ??
                    () => Navigator.of(
                      context,
                    ).pushNamed(TurnoCreateScreen.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurniCalendarCard extends StatelessWidget {
  const _TurniCalendarCard();

  static const _days = ['Lu', 'Ma', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const _dates = ['13', '14', '15', '16', '17', '18', '19'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 133,
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: AppSizes.p6,
            offset: Offset(0, AppSizes.p4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p14,
        AppSizes.p16,
        AppSizes.p8,
        AppSizes.p10,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
              _days.length,
              (index) => Expanded(
                child: Text(
                  _days[index],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textMutedLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p14),
          Row(
            children: List.generate(
              _dates.length,
              (index) => Expanded(
                child: Text(
                  _dates[index],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textMutedLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const _CalendarLegendDot(color: Color(0xFF00F529), label: 'FP'),
              const SizedBox(width: AppSizes.p24),
              const _CalendarLegendDot(color: Color(0xFFFF8819), label: 'MR'),
              const SizedBox(width: AppSizes.p24),
              const _CalendarLegendDot(color: Color(0xFFC455F2), label: 'AL'),
              const Spacer(),
              InkWell(
                onTap: () => _showExtendedCalendar(context),
                borderRadius: BorderRadius.circular(AppSizes.radius8),
                child: const Padding(
                  padding: EdgeInsets.all(AppSizes.p2),
                  child: Icon(
                    Icons.fullscreen_rounded,
                    color: AppColors.brandAccent,
                    size: AppSizes.p32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExtendedCalendar(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.darkBackground.withValues(alpha: 0.78),
      builder: (_) => const Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p24,
        ),
        child: _ExtendedCalendarDialog(),
      ),
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
          width: AppSizes.p20,
          height: AppSizes.p20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.p5),
        Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textMutedLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyTurniPanel extends StatelessWidget {
  const _EmptyTurniPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p40),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        border: Border.all(color: AppColors.errorStrong, width: 1.5),
      ),
      child: Text(
        'Non ci sono turni per adesso...\nCreane subito uno nuovo!',
        style: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.statusPositive,
          fontSize: 25,
          height: 1.16,
          fontWeight: FontWeight.w800,
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
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.p18),
          side: const BorderSide(color: AppColors.textMutedLight, width: 2),
        ),
        elevation: AppSizes.p6,
      ),
      child: Text(
        'Inserisci turno',
        style: AppTextStyles.buttonCompact.copyWith(
          fontSize: 29,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExtendedCalendarDialog extends StatelessWidget {
  const _ExtendedCalendarDialog();

  static const _weekdays = ['Lu', 'Ma', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const _days = [
    '',
    '',
    '',
    '',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.brandAccent, width: 2),
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
        AppSizes.p16,
        AppSizes.p16,
        AppSizes.p18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Calendario',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.brandAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Maggio',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textOnDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          Row(
            children: _weekdays
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textMutedLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSizes.p8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: AppSizes.p8,
              crossAxisSpacing: AppSizes.p6,
            ),
            itemBuilder: (context, index) {
              final day = _days[index];
              return _CalendarDayCell(day: day, marker: _markerForDay(day));
            },
          ),
          const SizedBox(height: AppSizes.p18),
          const Wrap(
            spacing: AppSizes.p24,
            runSpacing: AppSizes.p10,
            children: [
              _CalendarLegendDot(color: Color(0xFF00F529), label: 'FP'),
              _CalendarLegendDot(color: Color(0xFFFF8819), label: 'MR'),
              _CalendarLegendDot(color: Color(0xFFC455F2), label: 'AL'),
            ],
          ),
        ],
      ),
    );
  }

  static Color? _markerForDay(String day) {
    return switch (day) {
      '13' => const Color(0xFF00F529),
      '14' => const Color(0xFFFF8819),
      '15' => const Color(0xFFC455F2),
      '16' || '17' || '18' || '19' => AppColors.brandAccent,
      _ => null,
    };
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({required this.day, required this.marker});

  final String day;
  final Color? marker;

  @override
  Widget build(BuildContext context) {
    if (day.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: marker == null
            ? AppColors.transparent
            : marker!.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: marker == null ? null : Border.all(color: marker!, width: 1.2),
      ),
      child: Text(
        day,
        style: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.textOnDark,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
