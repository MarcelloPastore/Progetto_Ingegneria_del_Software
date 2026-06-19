import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Generic section header label used across profile and list screens.
///
/// Replaces private `_SectionTitle` / `_SectionHeader` widgets scattered across features.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.color = AppColors.textMuted,
    this.fontSize = 16,
  });

  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyStrong.copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
