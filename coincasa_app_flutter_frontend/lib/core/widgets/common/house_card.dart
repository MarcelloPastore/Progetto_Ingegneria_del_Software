import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class HouseCard extends StatelessWidget {
  const HouseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.p16),
    this.margin = EdgeInsets.zero,
    this.radius = AppSizes.radius16,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: AppSizes.p18,
            offset: Offset(0, AppSizes.p8),
          ),
        ],
      ),
      child: child,
    );
  }
}
