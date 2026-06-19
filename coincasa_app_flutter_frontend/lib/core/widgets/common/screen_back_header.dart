import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ScreenBackHeader extends StatelessWidget {
  const ScreenBackHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.brandAccent,
            size: AppSizes.p28,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: AppSizes.p32,
            minHeight: AppSizes.p32,
          ),
        ),
        const SizedBox(width: AppSizes.p6),
        Text(
          title,
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.brandAccent,
            fontSize: AppSizes.p23,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
