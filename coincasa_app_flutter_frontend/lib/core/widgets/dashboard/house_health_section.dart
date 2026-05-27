import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'dashboard_section_title.dart';

class HouseHealthSection extends StatelessWidget {
  const HouseHealthSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle('SALUTE DELLA CASA'),
        const SizedBox(height: AppSizes.p14),
        Container(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Flexible(
                fit: FlexFit.loose,
                child: _HealthBadge(
                  color: AppColors.statusNegative,
                  label: 'Oggi',
                  caption: 'Cucina',
                ),
              ),
              SizedBox(width: AppSizes.p12),
              Flexible(
                fit: FlexFit.loose,
                child: _HealthBadge(
                  color: AppColors.statusWarning,
                  label: '3gg',
                  caption: 'pulizie Bagno',
                ),
              ),
              SizedBox(width: AppSizes.p12),
              Flexible(
                fit: FlexFit.loose,
                child: _HealthBadge(
                  color: AppColors.statusPositive,
                  label: '7gg',
                  caption: 'Soggiorno',
                ),
              ),
              SizedBox(width: AppSizes.p12),
              Flexible(
                fit: FlexFit.loose,
                child: _HealthBadge(
                  color: AppColors.statusNeutral,
                  label: '10gg',
                  caption: 'Camere',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({
    required this.color,
    required this.label,
    required this.caption,
  });

  final Color color;
  final String label;
  final String caption;

  static const double _badgeSize = AppSizes.p68;

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
              color: color.withValues(alpha: 0.14),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: AppSizes.p4,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.dashboardBadgeLabel.copyWith(color: color),
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: AppTextStyles.dashboardBadgeCaption,
          ),
        ],
      ),
    );
  }
}
