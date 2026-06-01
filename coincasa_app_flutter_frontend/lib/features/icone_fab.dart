import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/turni/screens/turno_create_screen.dart';

class DashboardFabActionsPanel extends StatelessWidget {
  const DashboardFabActionsPanel({super.key, required this.onActionSelected});

  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSizes.radius24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: AppSizes.p14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _DashboardFabAction(
            label: 'Nuova spesa',
            assetPath: 'assets/Icons/💵Spese.png',
            backgroundColor: AppColors.statusInfo,
            routeName: '/spese/nuovo',
            onActionSelected: onActionSelected,
          ),
          _DashboardFabAction(
            label: 'Nuovo turno',
            assetPath: 'assets/Icons/🧹Turni.png',
            backgroundColor: AppColors.statusSuccess,
            routeName: TurnoCreateScreen.routeName,
            onActionSelected: onActionSelected,
          ),
          _DashboardFabAction(
            label: 'Nuova scadenza',
            assetPath: 'assets/Icons/⏰Scadenza.png',
            backgroundColor: AppColors.statusWarning,
            routeName: '/scadenze',
            onActionSelected: onActionSelected,
          ),
          _DashboardFabAction(
            label: 'Nuovo problema',
            assetPath: 'assets/Icons/💥Problemi.png',
            backgroundColor: AppColors.statusNegative,
            routeName: '/problemi',
            onActionSelected: onActionSelected,
          ),
        ],
      ),
    );
  }
}

class _DashboardFabAction extends StatelessWidget {
  const _DashboardFabAction({
    required this.label,
    required this.assetPath,
    required this.backgroundColor,
    required this.routeName,
    required this.onActionSelected,
  });

  final String label;
  final String assetPath;
  final Color backgroundColor;
  final String routeName;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onActionSelected(routeName),
      borderRadius: BorderRadius.circular(AppSizes.radius24),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: backgroundColor,
              shape: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p12),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Image.asset(assetPath, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              label,
              style: AppTextStyles.dashboardCardLabel.copyWith(
                fontSize: 12,
                color: AppColors.textOnDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
