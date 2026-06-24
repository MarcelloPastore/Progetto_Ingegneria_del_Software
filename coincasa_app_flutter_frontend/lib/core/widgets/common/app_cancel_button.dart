import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppCancelButton extends StatelessWidget {
  const AppCancelButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p30),
      child: SizedBox(
        height: AppSizes.p56,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.errorContainerDark,
            side: BorderSide(
              color: enabled ? AppColors.errorStrong : AppColors.errorStrong.withValues(alpha: 0.5), 
              width: AppSizes.p2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius18),
            ),
          ),
          child: Text(
            'Annulla',
            style: AppTextStyles.buttonCompact.copyWith(
              color: enabled ? AppColors.errorStrong : AppColors.errorStrong.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
