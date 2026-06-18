import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onCta,
    this.iconBackgroundColor,
  });

  final Widget icon;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onCta;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconArea(icon: icon, backgroundColor: iconBackgroundColor),
          const SizedBox(height: AppSizes.p24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong,
          ),
          const SizedBox(height: AppSizes.p12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMutedRelaxed.copyWith(
              color: AppColors.textMutedLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSizes.p32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius15),
                ),
              ),
              child: Text(ctaLabel, style: AppTextStyles.buttonCompact),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconArea extends StatelessWidget {
  const _IconArea({required this.icon, this.backgroundColor});

  final Widget icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (backgroundColor == null) {
      return SizedBox(width: 145, height: 145, child: icon);
    }
    return Container(
      width: 145,
      height: 145,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      alignment: Alignment.center,
      child: icon,
    );
  }
}
