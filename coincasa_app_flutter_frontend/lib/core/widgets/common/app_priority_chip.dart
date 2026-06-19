import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppPriorityChip extends StatelessWidget {
  const AppPriorityChip({
    super.key,
    required this.label,
    required this.bgColor,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p14),
        decoration: BoxDecoration(
          gradient: AppGradients.buttonGradient(bgColor),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: selected ? AppColors.brandAccent : AppColors.darkBackground,
            width: AppSizes.p3,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.black.withValues(alpha: 0.45)
                  : AppColors.shadowStrong,
              blurRadius: selected ? AppSizes.p8 : AppSizes.p6,
              offset: Offset(0, selected ? AppSizes.p4 : AppSizes.p3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: dotColor, size: AppSizes.p18),
            const SizedBox(width: AppSizes.p2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: AppSizes.p15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
