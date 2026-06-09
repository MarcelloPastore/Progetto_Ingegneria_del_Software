import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'dashboard_section_title.dart';

class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  static const List<String> _weekDays = [
    'Lu',
    'Ma',
    'Me',
    'Gi',
    'Ve',
    'Sa',
    'Do',
  ];
  static const List<int> _days = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
  ];
  static const Map<int, Color> _markers = {
    1: AppColors.statusSuccess,
    8: AppColors.statusWarning,
    9: AppColors.statusNegative,
    12: AppColors.statusInfo,
    15: AppColors.statusSuccess,
    22: AppColors.statusWarning,
    27: AppColors.statusNegative,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle('CALENDARIO SCADENZE'),
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
          padding: const EdgeInsets.only(
            top: AppSizes.p18,
            left: AppSizes.p18,
            right: AppSizes.p18,
            bottom: AppSizes.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: AppSizes.p16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  const Text(
                    'Aprile',
                    style: AppTextStyles.dashboardSectionMonth,
                  ),
                  const SizedBox(width: AppSizes.p12),
                  IconButton(
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: AppSizes.p16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekDays
                    .map(
                      (name) => Expanded(
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.dashboardCalendarWeekday,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSizes.p12),
              GridView.builder(
                itemCount: _days.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: AppSizes.p6,
                  crossAxisSpacing: AppSizes.p6,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final markerColor = _markers[day];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(AppSizes.radius14),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: AppSizes.p10,
                          child: Text(
                            day.toString(),
                            style: AppTextStyles.dashboardCalendarDay,
                          ),
                        ),
                        if (markerColor != null)
                          Positioned(
                            bottom: AppSizes.p2,
                            child: Container(
                              width: AppSizes.p8,
                              height: AppSizes.p8,
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSizes.p18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CalendarLegendDot(
                    color: AppColors.statusSuccess,
                    label: 'Turni',
                  ),
                  _CalendarLegendDot(
                    color: AppColors.statusWarning,
                    label: 'Spese',
                  ),
                  _CalendarLegendDot(
                    color: AppColors.statusNegative,
                    label: 'Problemi',
                  ),
                  _CalendarLegendDot(
                    color: AppColors.statusInfo,
                    label: 'Scadenze',
                  ),
                ],
              ),
            ],
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
      children: [
        Container(
          width: AppSizes.p10,
          height: AppSizes.p10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.p6),
        Text(label, style: AppTextStyles.dashboardLegendLabel),
      ],
    );
  }
}
