import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class SpesaAllegaScontrinoButton extends StatelessWidget {
  const SpesaAllegaScontrinoButton({
    super.key,
    required this.hasAttachment,
    required this.onTap,
    required this.onRemove,
  });

  final bool hasAttachment;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return hasAttachment ? _buildAttached() : _buildEmpty();
  }

  Widget _buildEmpty() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p14,
          vertical: AppSizes.p12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: AppColors.textOnDark.withValues(alpha: 0.20),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.textMuted,
              size: AppSizes.p18,
            ),
            const SizedBox(width: AppSizes.p8),
            Text(
              'Allega scontrino (opzionale)',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.textMuted,
                fontSize: AppSizes.p14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttached() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p14,
        AppSizes.p10,
        AppSizes.p8,
        AppSizes.p10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(
          color: AppColors.brandAccent.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.brandAccent,
            size: AppSizes.p18,
          ),
          const SizedBox(width: AppSizes.p8),
          Expanded(
            child: Text(
              'Scontrino allegato',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.brandAccent,
                fontSize: AppSizes.p14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(AppSizes.p4),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.textMuted,
                size: AppSizes.p18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
