import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'dashboard_section_title.dart';

class UpcomingDeadlinesSection extends StatelessWidget {
  const UpcomingDeadlinesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle('PROSSIME SCADENZE'),
        const SizedBox(height: AppSizes.p14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: AppSizes.p20,
                offset: Offset(0, AppSizes.p8),
              ),
            ],
          ),
          child: Column(
            children: const [
              _DeadlineRow(
                icon: Icons.home,
                title: 'Affitto',
                statusText: '3 giorni',
                statusColor: AppColors.statusNegative,
              ),
              _DeadlineRow(
                icon: Icons.lightbulb,
                title: 'Bolletta luce',
                statusText: '10 giorni',
                statusColor: AppColors.statusWarning,
              ),
              _DeadlineRow(
                icon: Icons.wifi,
                title: 'Internet',
                statusText: 'oggi',
                statusColor: AppColors.statusSuccess,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({
    required this.icon,
    required this.title,
    required this.statusText,
    required this.statusColor,
  });

  final IconData icon;
  final String title;
  final String statusText;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p18,
        vertical: AppSizes.p12,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.p42,
            height: AppSizes.p42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppSizes.radius14),
            ),
            child: Icon(icon, color: statusColor, size: AppSizes.p22),
          ),
          const SizedBox(width: AppSizes.p14),
          Expanded(child: Text(title, style: AppTextStyles.dashboardListTitle)),
          Text(
            statusText,
            style: AppTextStyles.dashboardListStatus.copyWith(
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
