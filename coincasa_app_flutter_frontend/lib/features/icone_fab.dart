import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/problemi/screens/FAB_problemi_screen.dart';
import 'package:coincasa_app/features/scadenze/screens/fab_scadenza.dart';
import 'package:coincasa_app/features/spese/screens/inserisci_spesa_admin.dart';
import 'package:coincasa_app/features/turni/screens/turni_screen_principale.dart';

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
    final popupWidth = screenSize.width < 450 ? screenSize.width - 20 : 410.0;
    final popupHeight = 850.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      backgroundColor: Colors.transparent,
      child: Container(
        width: popupWidth,
        height: popupHeight,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 2, color: Color(0xFF996CFA)),
            borderRadius: BorderRadius.circular(15),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _CreateTabBar(
                  selectedTab: _selectedTab,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                  child: _PopupBody(tab: _selectedTab),
                ),
              ),
            ],
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
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFD2D2D2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
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
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF996CFA)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _labelFor(tab),
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF727272),
                      fontSize: 13,
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
