import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/ui/problemi/screens/fab_segnala_problema_screen.dart';
import 'package:coincasa_app/ui/scadenze/screens/fab_crea_scadenza.dart';
import 'package:coincasa_app/ui/spese/screens/form_crea_spesa.dart';
import 'package:coincasa_app/ui/turni/screens/crea_turno_dialog.dart';

enum DashboardCreateTab { spesa, problema, turno, scadenza }

class DashboardCreatePopup extends StatefulWidget {
  const DashboardCreatePopup({super.key});

  @override
  State<DashboardCreatePopup> createState() => _DashboardCreatePopupState();
}

class _DashboardCreatePopupState extends State<DashboardCreatePopup> {
  DashboardCreateTab _selectedTab = DashboardCreateTab.spesa;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final popupWidth = screenSize.width * 0.95;
    final popupHeight = screenSize.height * 0.85;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: popupWidth,
          height: popupHeight,
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 2, color: AppColors.featureAccent),
              borderRadius: BorderRadius.circular(AppSizes.p15),
            ),
            shadows: const [
              BoxShadow(
                color: AppColors.shadowOverlay,
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.p13),
            child: Column(
              children: [
                const SizedBox(height: AppSizes.p8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
                  child: _CreateTabBar(
                    selectedTab: _selectedTab,
                    onChanged: (tab) => setState(() => _selectedTab = tab),
                  ),
                ),
                const SizedBox(height: AppSizes.p8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.p12,
                      AppSizes.p0,
                      AppSizes.p12,
                      AppSizes.p22,
                    ),
                    child: _PopupBody(tab: _selectedTab),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateTabBar extends StatelessWidget {
  const _CreateTabBar({required this.selectedTab, required this.onChanged});

  final DashboardCreateTab selectedTab;
  final ValueChanged<DashboardCreateTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.p42,
      decoration: BoxDecoration(
        color: AppColors.dialogTabBarSurface,
        borderRadius: BorderRadius.circular(AppSizes.p15),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowPressed,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: DashboardCreateTab.values.map((tab) {
          final isSelected = selectedTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(tab),
              borderRadius: BorderRadius.circular(AppSizes.radius14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.featureAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radius14),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _labelFor(tab),
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: isSelected
                          ? AppColors.textOnDark
                          : AppColors.textMuted,
                      fontSize: AppSizes.p13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _labelFor(DashboardCreateTab tab) {
    return switch (tab) {
      DashboardCreateTab.spesa => 'Spesa',
      DashboardCreateTab.problema => 'Problema',
      DashboardCreateTab.turno => 'Turno',
      DashboardCreateTab.scadenza => 'Scadenza',
    };
  }
}

class _PopupBody extends StatelessWidget {
  const _PopupBody({required this.tab});

  final DashboardCreateTab tab;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      DashboardCreateTab.spesa => const InserisciSpesaPopupContent(),
      DashboardCreateTab.problema => const ProblemiPopupPanel(
        useSafeArea: false,
        showTabs: false,
        showFrame: false,
        showHeader: false,
      ),
      DashboardCreateTab.turno => const TurniPopupPanel(
        useSafeArea: false,
        showTabs: false,
        showFrame: false,
      ),
      DashboardCreateTab.scadenza => const FabScadenzaPanel(),
    };
  }
}
