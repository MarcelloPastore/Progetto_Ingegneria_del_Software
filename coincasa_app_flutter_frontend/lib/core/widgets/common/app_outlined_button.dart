import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.brandPrimary;
    final canPress = onPressed != null && !isLoading;

    final content = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: AppSizes.p16,
                height: AppSizes.p16,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.p2,
                  valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Text(label, style: AppTextStyles.buttonCompact),
            ],
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppTextStyles.buttonCompact),
          );

    return OutlinedButton(
      onPressed: canPress ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        side: BorderSide(color: buttonColor, width: AppSizes.p2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
      ),
      child: content,
    );
  }
}
