import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_sizes.dart';

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
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(bgColor, Colors.white, 0.30)!,
        bgColor,
        Color.lerp(bgColor, Colors.black, 0.18)!,
      ],
      stops: const [0, 0.62, 1],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: selected ? AppColors.brandAccent : AppColors.darkBackground,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.black.withValues(alpha: 0.45)
                  : AppColors.shadowStrong,
              blurRadius: selected ? 8 : 6,
              offset: Offset(0, selected ? 4 : 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: dotColor, size: 18),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: 15,
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
