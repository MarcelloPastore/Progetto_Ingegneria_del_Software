import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppCancelButton extends StatelessWidget {
  const AppCancelButton({super.key, required this.onPressed, this.enabled = true});
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.p54,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppSizes.radius15),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radius15),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.7),
                  width: AppSizes.p2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Annulla',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.errorStrong,
                  fontSize: AppSizes.p20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
