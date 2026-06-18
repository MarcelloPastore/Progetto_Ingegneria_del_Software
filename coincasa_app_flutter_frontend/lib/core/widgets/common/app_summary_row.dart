import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppSummaryRow extends StatelessWidget {
  const AppSummaryRow({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(
              color: const Color(0xFFAFAEAE),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyStrong.copyWith(
              color: valueColor ?? AppColors.textOnDark,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
