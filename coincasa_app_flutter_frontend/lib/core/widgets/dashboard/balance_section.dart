import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class BalanceSection extends StatelessWidget {
  const BalanceSection({super.key});

  static const double _totaleHorizontalShift = AppSizes.p14;
  static const EdgeInsets _amountPadding = EdgeInsets.only(right: AppSizes.p40);

  static Offset get _totaleOffset =>
      const Offset(_totaleHorizontalShift, AppSizes.p4);

  @override
  Widget build(BuildContext context) {
    return Container(
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
        vertical: AppSizes.p12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Transform.translate(
                  offset: _totaleOffset,
                  child: const Text(
                    'Totale',
                    style: AppTextStyles.dashboardBalanceTitle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/Icons/Arrow up-right.svg',
                width: AppSizes.p30,
                height: AppSizes.p30,
                colorFilter: const ColorFilter.mode(
                  AppColors.brandAccent,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p18),
          Padding(
            padding: _amountPadding,
            child: const Center(
              child: Text('-€15', style: AppTextStyles.dashboardBalanceAmount),
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          const Divider(color: AppColors.dividerOnDark, height: 1),
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Da ricevere',
                      style: AppTextStyles.dashboardCardLabel,
                    ),
                    SizedBox(height: AppSizes.p6),
                    Text(
                      '+€24',
                      style: AppTextStyles.dashboardCardPositiveValue,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: AppSizes.p42,
                color: AppColors.dividerOnDark,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSizes.p20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Devi pagare',
                        style: AppTextStyles.dashboardCardLabel,
                      ),
                      SizedBox(height: AppSizes.p6),
                      Text(
                        '€39',
                        style: AppTextStyles.dashboardCardNegativeValue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
