import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/problemi/screens/segnala_problema_screen.dart';

class HouseQuickNav extends StatelessWidget {
  const HouseQuickNav({super.key, required this.currentRoute});

  final String currentRoute;

  static const List<_HouseNavEntry> _entries = [
    _HouseNavEntry(
      label: 'Home',
      asset: 'assets/Icons/home.png',
      route: '/dashboard',
    ),
    _HouseNavEntry(
      label: 'Spese',
      asset: 'assets/Icons/spese.png',
      route: '/spese',
    ),
    _HouseNavEntry(
      label: 'Turni',
      asset: 'assets/Icons/turni.png',
      route: '/turni',
    ),
    _HouseNavEntry(
      label: 'Scadenze',
      asset: 'assets/Icons/reminder.png',
      route: '/scadenze',
    ),
    _HouseNavEntry(
      label: 'Problemi',
      asset: 'assets/Icons/problemi.png',
      route: '/problemi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.p88,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p8,
        AppSizes.p10,
        AppSizes.p8,
        AppSizes.p8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _entries
            .map(
              (entry) => Expanded(
                child: _HouseBottomNavItem(
                  entry: entry,
                  selected: _isSelected(entry.route, currentRoute),
                  currentRoute: currentRoute,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  static bool _isSelected(String entryRoute, String currentRoute) {
    if (entryRoute == '/problemi') {
      return currentRoute == '/problemi' ||
          currentRoute == SegnalaProblemaScreen.routeName;
    }

    return entryRoute == currentRoute;
  }
}

class _HouseBottomNavItem extends StatelessWidget {
  const _HouseBottomNavItem({
    required this.entry,
    required this.selected,
    required this.currentRoute,
  });

  final _HouseNavEntry entry;
  final bool selected;
  final String currentRoute;

  void _onTap(BuildContext context) {
    if (selected) {
      // Già nella sezione corretta: torna alla schermata principale
      // della sezione facendo pop di tutte le route fino alla root.
      Navigator.of(context).popUntil(
        (route) => route.settings.name == entry.route || route.isFirst,
      );
      return;
    }

    // Naviga a una sezione diversa: rimuove tutto lo stack corrente
    // e sostituisce con la root della nuova sezione, senza animazione.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(entry.route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.statusInfo : AppColors.textOnDark;

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              entry.asset,
              width: AppSizes.p32,
              height: AppSizes.p32,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSizes.p2),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  entry.label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontSize: AppSizes.p15,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    decoration: selected
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: color,
                    decorationThickness: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseNavEntry {
  const _HouseNavEntry({
    required this.label,
    required this.asset,
    required this.route,
  });

  final String label;
  final String asset;
  final String route;
}
