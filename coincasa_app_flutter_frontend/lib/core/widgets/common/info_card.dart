import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSizes.p8),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}
