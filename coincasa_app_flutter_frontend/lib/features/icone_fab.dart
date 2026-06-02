import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
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
    final popupWidth = screenSize.width < 399 ? screenSize.width - 32 : 367.0;
    final popupHeight = screenSize.height < 690
        ? screenSize.height - 64
        : 638.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CreateTabBar(
                  selectedTab: _selectedTab,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
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
      DashboardCreateTab.problema => const _ShortcutPanel(
        title: 'Nuovo Problema',
        icon: Icons.report_problem,
        description:
            'Apri la sezione problemi per registrare o seguire una segnalazione.',
        buttonLabel: 'Vai ai problemi',
        routeName: '/problemi',
      ),
      DashboardCreateTab.turno => const TurniPopupPanel(
        useSafeArea: false,
        showTabs: false,
        showFrame: false,
      ),
      DashboardCreateTab.scadenza => const _ShortcutPanel(
        title: 'Nuova Scadenza',
        icon: Icons.event_note,
        description:
            'Apri la sezione scadenze per consultare e gestire le date importanti.',
        buttonLabel: 'Vai alle scadenze',
        routeName: '/scadenze',
      ),
    };
  }
}

class _ShortcutPanel extends StatelessWidget {
  const _ShortcutPanel({
    required this.title,
    required this.icon,
    required this.description,
    required this.buttonLabel,
    required this.routeName,
  });

  final String title;
  final IconData icon;
  final String description;
  final String buttonLabel;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 76, color: const Color(0xFF5228AD)),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.brandPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: const Color(0xFF727272),
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.pushNamed(routeName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA48DDA),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              buttonLabel,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
