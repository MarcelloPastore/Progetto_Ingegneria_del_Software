import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class AppOtpInput extends StatelessWidget {
  const AppOtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hasError = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppColors.error : AppColors.inputBorderDark;

    return Container(
      width: double.infinity,
      height: AppSizes.p102,
      decoration: BoxDecoration(
        color: AppColors.inputFillDark,
        border: Border.all(color: borderColor, width: AppSizes.p2),
        borderRadius: BorderRadius.circular(AppSizes.radius15),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          style: AppTextStyles.input.copyWith(
            fontSize: AppSizes.p34,
            letterSpacing: AppSizes.p24,
          ),
          cursorColor: AppColors.focus,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            counterText: '',
            isCollapsed: true,
            filled: false,
          ),
        ),
      ),
    );
  }
}
