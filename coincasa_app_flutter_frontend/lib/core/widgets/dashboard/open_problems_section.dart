import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'dashboard_section_title.dart';

class OpenProblemsSection extends StatelessWidget {
  const OpenProblemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle('PROBLEMI APERTI'),
        const SizedBox(height: AppSizes.p14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(AppSizes.radius24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: AppSizes.p20,
                offset: Offset(0, AppSizes.p8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p18,
            vertical: AppSizes.p16,
          ),
          child: Column(
            children: [
              const _ProblemRow(
                initials: 'FP',
                title: 'Lavatrice rotta',
                status: 'urgente',
                color: AppColors.statusNegative,
              ),
              const _ProblemRow(
                initials: 'AL',
                title: 'Perdita rubinetto',
                status: 'media',
                color: AppColors.statusWarning,
              ),
              const _ProblemRow(
                initials: 'MC',
                title: 'Caldaia rotta',
                status: 'oggi',
                color: AppColors.statusSuccess,
              ),
              const SizedBox(height: AppSizes.p10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vedi tutti',
                  style: AppTextStyles.dashboardSectionLink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProblemRow extends StatelessWidget {
  const _ProblemRow({
    required this.initials,
    required this.title,
    required this.status,
    required this.color,
  });

  final String initials;
  final String title;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizes.p23,
            backgroundColor: color.withOpacity(0.18),
            child: Text(
              initials,
              style: AppTextStyles.dashboardProblemInitials.copyWith(
                color: color,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.p14),
          Expanded(
            child: Text(title, style: AppTextStyles.dashboardCardTitleOnDark),
          ),
          Text(
            status,
            style: AppTextStyles.dashboardListStatus.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
