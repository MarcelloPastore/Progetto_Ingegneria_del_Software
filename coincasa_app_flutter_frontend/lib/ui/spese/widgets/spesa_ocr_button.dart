import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class SpesaOcrButton extends StatelessWidget {
  const SpesaOcrButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  static const _size = AppSizes.p48;
  static const _borderRadius = BorderRadius.all(
    Radius.circular(AppSizes.radius12),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          gradient: AppGradients.blueCta,
          shape: RoundedRectangleBorder(borderRadius: _borderRadius),
          shadows: [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p6,
              offset: Offset(0, AppSizes.p3),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.transparent,
            foregroundColor: AppColors.textOnDark,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
            elevation: AppSizes.p0,
            shadowColor: AppColors.transparent,
          ),
          child: const Icon(
            Icons.document_scanner,
            color: AppColors.textOnDark,
            size: AppSizes.p24,
          ),
        ),
      ),
    );
  }
}
