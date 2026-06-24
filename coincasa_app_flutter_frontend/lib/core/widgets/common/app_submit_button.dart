import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppSubmitButton extends StatelessWidget {
  const AppSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && !isLoading;
    return Opacity(
      opacity: effectiveEnabled ? 1.0 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.p58,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.brandPurple,
            borderRadius: BorderRadius.circular(AppSizes.radius16),
          ),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              onTap: effectiveEnabled ? onPressed : null,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: AppSizes.p22,
                        height: AppSizes.p22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textOnDark,
                          ),
                        ),
                      )
                    : Text(
                        label,
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: AppSizes.p22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
