import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppTaskField extends StatelessWidget {
  const AppTaskField({
    super.key,
    required this.controller,
    required this.hasError,
    required this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  OutlineInputBorder _outline(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      borderSide: BorderSide(color: color, width: AppSizes.p2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      style: AppTextStyles.input.copyWith(
        color: AppColors.textOnDark,
        fontSize: AppSizes.p20,
      ),
      decoration: InputDecoration(
        hintText: 'Nome task...',
        suffixText: hasError ? '*' : null,
        suffixStyle: AppTextStyles.input.copyWith(
          color: AppColors.errorStrong,
          fontSize: AppSizes.p22,
          fontWeight: FontWeight.w900,
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: hasError
              ? AppColors.errorStrong
              : AppColors.textMutedLight,
          fontSize: AppSizes.p20,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated.withValues(alpha: 0.86),
        contentPadding: const EdgeInsets.fromLTRB(
          AppSizes.p13,
          AppSizes.p13,
          AppSizes.p13,
          AppSizes.p12,
        ),
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
