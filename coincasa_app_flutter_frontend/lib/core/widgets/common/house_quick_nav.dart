import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

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
      height: 88,
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
                  selected: entry.route == currentRoute,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _HouseBottomNavItem extends StatelessWidget {
  const _HouseBottomNavItem({required this.entry, required this.selected});

  final _HouseNavEntry entry;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.statusInfo : AppColors.textOnDark;

    return InkWell(
      onTap: selected
          ? null
          : () => Navigator.of(context).pushReplacementNamed(entry.route),
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            entry.asset,
            width: AppSizes.p32,
            height: AppSizes.p32,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSizes.p2),
          Text(
            entry.label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: selected
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: color,
              decorationThickness: 1.5,
            ),
          ),
        ],
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
