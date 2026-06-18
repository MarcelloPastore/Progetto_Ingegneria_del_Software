import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CoinquiliniNotifiedBanner extends StatelessWidget {
  const CoinquiliniNotifiedBanner({
    super.key,
    this.message = 'Tutti i coinquilini sono stati avvisati.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p16,
      ),
      decoration: BoxDecoration(
        color: AppColors.successBright.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radius14),
        border: Border.all(color: AppColors.statusPositive, width: 1.5),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.statusPositive,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
