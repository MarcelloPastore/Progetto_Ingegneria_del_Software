import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.hasError = false,
    this.showRequired = false,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.minLines,
    this.maxLines = 1,
    this.errorText,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final bool hasError;
  final bool showRequired;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? minLines;
  final int? maxLines;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final showAsterisk = showRequired || hasError;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius7),
      borderSide: hasError
          ? const BorderSide(color: AppColors.error, width: AppSizes.p2)
          : BorderSide.none,
    );

    Widget field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      minLines: minLines,
      maxLines: maxLines,
      style: AppTextStyles.input.copyWith(
        color: hasError ? AppColors.error : AppColors.textOnDark,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.inputHint,
        filled: true,
        fillColor: AppColors.inputFillDark,
        contentPadding: AppSizes.inputContent,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );

    if (label == null && errorText == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.p4, bottom: AppSizes.p4),
            child: RichText(
              text: TextSpan(
                text: label,
                style: AppTextStyles.label,
                children: showAsterisk
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ]
                    : const [],
              ),
            ),
          ),
        field,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.p4),
            child: Row(
              children: [
                const Icon(Icons.error_rounded, color: AppColors.error, size: AppSizes.p14),
                const SizedBox(width: AppSizes.p4),
                Text(
                  errorText!,
                  style: AppTextStyles.fieldError,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
