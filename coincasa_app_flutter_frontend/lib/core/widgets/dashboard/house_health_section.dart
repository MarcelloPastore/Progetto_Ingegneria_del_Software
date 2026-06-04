import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'dashboard_section_title.dart';

class HouseHealthBadgeData {
  const HouseHealthBadgeData({required this.caption, this.lastCleaningDate});

  final String caption;
  final DateTime? lastCleaningDate;
}

class HouseHealthSection extends StatelessWidget {
  const HouseHealthSection({
    super.key,
    required this.badges,
    this.routeName = '/turni',
  });

  final List<HouseHealthBadgeData> badges;
  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle('SALUTE DELLA CASA'),
        const SizedBox(height: AppSizes.p14),
        InkWell(
          onTap: routeName == null
              ? null
              : () => Navigator.of(context).pushNamed(routeName!),
          borderRadius: BorderRadius.circular(AppSizes.radius24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.circular(AppSizes.radius24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowStrong,
                  blurRadius: AppSizes.p25,
                  offset: Offset(0, AppSizes.p10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p20,
              vertical: AppSizes.p18,
            ),
            child: badges.isEmpty
                ? const Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Nessun turno disponibile',
                            style: AppTextStyles.dashboardBadgeCaption,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : badges.length > 4
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(badges.length, (index) {
                            final badge = badges[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == badges.length - 1
                                    ? 0
                                    : AppSizes.p18,
                              ),
                              child: _HealthBadge(data: badge),
                            );
                          }),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(badges.length, (index) {
                          final badge = badges[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == badges.length - 1
                                  ? 0
                                  : AppSizes.p18,
                            ),
                            child: _HealthBadge(data: badge),
                          );
                        }),
                      ),
          ),
        ),
      ],
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.data});

  final HouseHealthBadgeData data;

  static const double _badgeSize = AppSizes.p68;

  int? get _daysSinceCleaning {
    final date = data.lastCleaningDate;
    if (date == null) {
      return null;
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final days = todayOnly.difference(dateOnly).inDays;
    return days < 0 ? 0 : days;
  }

  String get _label {
    final days = _daysSinceCleaning;
    if (days == null) {
      return '--';
    }
    if (days == 0) {
      return 'Oggi';
    }
    return '${days}gg';
  }

  Color get _color {
    final days = _daysSinceCleaning;
    if (days == null) {
      return const Color(0xFFE4E8F3);
    }
    if (days <= 1) {
      return const Color(0xFF38C85A);
    }
    if (days <= 3) {
      return const Color(0xFFFFA62B);
    }
    if (days <= 7) {
      return const Color(0xFFFF4D4D);
    }
    return const Color(0xFFDDE2EF);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _badgeSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: _badgeSize,
            width: _badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.16),
              border: Border.all(
                color: _color.withValues(alpha: 0.95),
                width: AppSizes.p5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _label,
              style: AppTextStyles.dashboardBadgeLabel.copyWith(color: _color),
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            data.caption,
            textAlign: TextAlign.center,
            style: AppTextStyles.dashboardBadgeCaption,
          ),
        ],
      ),
    );
  }
}
