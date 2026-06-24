import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

/// Toggle switch standard dell'app.
///
/// ON  → track [AppColors.brandPrimary], thumb bianco, icona ✓
/// OFF → track [AppColors.surfaceDarkMuted], thumb bianco, icona ✗
/// Disabled (onChanged == null) → colori attenuati, non interagibile
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.textOnDark,
      activeTrackColor:
          _enabled ? AppColors.brandPrimary : AppColors.dividerDark,
      inactiveThumbColor: AppColors.textOnDark,
      inactiveTrackColor: _enabled
          ? AppColors.surfaceDarkMuted
          : AppColors.dividerDark.withValues(alpha: 0.45),
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
        final isOn = states.contains(WidgetState.selected);
        if (isOn) {
          return Icon(
            Icons.check_rounded,
            size: AppSizes.p14,
            color: _enabled ? AppColors.brandSecondary : AppColors.textMutedDark,
          );
        }
        return Icon(
          Icons.close_rounded,
          size: AppSizes.p14,
          color: _enabled ? AppColors.textMutedDark : AppColors.dividerDark,
        );
      }),
    );
  }
}
