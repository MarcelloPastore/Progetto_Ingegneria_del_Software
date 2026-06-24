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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: selected ? AppSizes.p58 : AppSizes.p50,
        margin: EdgeInsets.symmetric(vertical: selected ? 0 : AppSizes.p4),
        decoration: BoxDecoration(
          gradient: AppGradients.priorityChip(
            bgColor: bgColor,
            isSelected: selected,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: selected ? dotColor : AppColors.transparent,
            width: selected ? 2.5 : 0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.55),
                    blurRadius: AppSizes.p18,
                    spreadRadius: AppSizes.p1,
                    offset: const Offset(0, AppSizes.p4),
                  ),
                  BoxShadow(
                    color: AppColors.darkBackground.withValues(alpha: 0.35),
                    blurRadius: AppSizes.p6,
                    offset: const Offset(0, AppSizes.p2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadowStrong,
                    blurRadius: AppSizes.p4,
                    offset: const Offset(0, AppSizes.p2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: dotColor,
                size: AppSizes.p16,
              )
            else
              Icon(Icons.circle, color: dotColor, size: AppSizes.p12),
            const SizedBox(width: AppSizes.p6),
            Text(
              label,
              style: selected
                  ? AppTextStyles.priorityChipSelected
                  : AppTextStyles.priorityChipUnselected,
            ),
          ],
        ),
      ),
    );
  }
}
