import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final canPress = onPressed != null && !isLoading;
    final content = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: AppSizes.p16,
                height: AppSizes.p16,
                child: const CircularProgressIndicator(
                  strokeWidth: AppSizes.p2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textOnDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Text(label, style: AppTextStyles.button),
            ],
          )
        : Text(label, style: AppTextStyles.button);

    return FilledButton(onPressed: canPress ? onPressed : null, child: content);
  }
}
