import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppCancelButtonPrimary extends StatelessWidget {
  const AppCancelButtonPrimary({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.p56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: enabled ? AppColors.brandPrimary : AppColors.brandPrimary.withValues(alpha: 0.5),
            width: AppSizes.p2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
          ),
        ),
        child: Text(
          'Annulla',
          style: AppTextStyles.buttonCompact.copyWith(
            color: enabled ? AppColors.brandPrimary : AppColors.brandPrimary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
