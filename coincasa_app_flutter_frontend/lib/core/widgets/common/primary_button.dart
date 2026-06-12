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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Text(label),
            ],
          )
        : Text(label);

    return FilledButton(onPressed: canPress ? onPressed : null, child: content);
  }
}
