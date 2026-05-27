import 'package:flutter/material.dart';

import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';

class ScadenzeScreen extends StatelessWidget {
  const ScadenzeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TodoScreen(
      title: 'Scadenze',
      message: 'TODO: gestione scadenze da implementare.',
      icon: Icons.event_outlined,
    );
  }
}

class _TodoScreen extends StatelessWidget {
  const _TodoScreen({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/scadenze'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
