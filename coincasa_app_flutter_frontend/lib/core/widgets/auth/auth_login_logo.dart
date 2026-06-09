import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class AuthLoginLogo extends StatelessWidget {
  const AuthLoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Icons/home_auth_icon.png',
      height: AppSizes.p110,
      width: AppSizes.p110,
      errorBuilder: (context, error, stackTrace) => Container(
        height: AppSizes.p110,
        width: AppSizes.p110,
        decoration: BoxDecoration(
          color: AppColors.brandPrimaryDark.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSizes.radius24),
        ),
        child: const Icon(
          Icons.home,
          size: AppSizes.p60,
          color: AppColors.focus,
        ),
      ),
    );
  }
}
