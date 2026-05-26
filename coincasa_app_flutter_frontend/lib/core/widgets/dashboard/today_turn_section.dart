import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'dashboard_section_title.dart';

class TodayTurnSection extends StatelessWidget {
  const TodayTurnSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle('TURNO DI OGGI'),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: AppSizes.p24,
                backgroundColor: AppColors.statusPositive,
                child: const Text(
                  'MR',
                  style: AppTextStyles.dashboardTurnInitials,
                ),
              ),
              const SizedBox(width: AppSizes.p14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Francesco - Pulizie Bagno',
                      style: AppTextStyles.dashboardCardTitleOnDark,
                    ),
                    SizedBox(height: AppSizes.p6),
                    Text(
                      'Notifica sera prima',
                      style: AppTextStyles.dashboardCardSubtitleOnDark,
                    ),
                  ],
                ),
              ),
              Text(
                'oggi',
                style: AppTextStyles.dashboardListStatus.copyWith(
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
