import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_sizes.dart';

class AppTaskField extends StatelessWidget {
  const AppTaskField({
    super.key,
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  OutlineInputBorder _outline(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      borderSide: BorderSide(color: color, width: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.input.copyWith(fontSize: 20),
      decoration: InputDecoration(
        hintText: 'Nome task...',
        suffixText: hasError ? '*' : null,
        suffixStyle: AppTextStyles.input.copyWith(
          color: AppColors.errorStrong,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: hasError ? AppColors.errorStrong : AppColors.textMutedLight,
          fontSize: 20,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated.withValues(alpha: 0.86),
        contentPadding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
        enabledBorder: _outline(
          hasError ? AppColors.errorStrong : AppColors.transparent,
        ),
        focusedBorder: _outline(
          hasError ? AppColors.errorStrong : AppColors.brandAccent,
        ),
      ),
    );
  }
}
