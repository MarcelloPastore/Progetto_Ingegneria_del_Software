import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Label-value row used in profile cards and detail screens.
///
/// Replaces private `_InfoRow` widgets in profilo_admin, profilo_coinquilino, etc.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;

  /// Defaults to [AppColors.textOnDark] when null.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColors.textMutedLight,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyStrong.copyWith(
              color: valueColor ?? AppColors.textOnDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
