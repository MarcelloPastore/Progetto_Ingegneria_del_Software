import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class FabSaveButton extends StatelessWidget {
  const FabSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.p56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimaryDark,
          disabledBackgroundColor: AppColors.textMutedDark,
          disabledForegroundColor: AppColors.textOnDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius18),
          ),
          elevation: AppSizes.p4,
        ),
        child: isLoading
            ? const SizedBox(
                width: AppSizes.p24,
                height: AppSizes.p24,
                child: CircularProgressIndicator(
                  color: AppColors.textOnDark,
                  strokeWidth: AppSizes.p2,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.buttonCompact.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
      ),
    );
  }
}

class FabCancelButton extends StatelessWidget {
  const FabCancelButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p30),
      child: SizedBox(
        height: AppSizes.p56,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.errorContainerStrong,
            side: const BorderSide(color: AppColors.errorStrong, width: AppSizes.p2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius18),
            ),
          ),
          child: Text(
            'Annulla',
            style: AppTextStyles.buttonCompact.copyWith(
              color: AppColors.errorStrong,
            ),
          ),
        ),
      ),
    );
  }
}
