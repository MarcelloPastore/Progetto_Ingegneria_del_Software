import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/empty_state_widget.dart';

class StatoVuoto extends StatelessWidget {
  const StatoVuoto({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: const Icon(
        Icons.calendar_today_rounded,
        size: 80,
        color: AppColors.brandAccent,
      ),
      title: 'Nessuna scadenza',
      description:
          'Aggiungi affitto, bollette e utenze per ricevere reminder automatici prima della scadenza.',
      ctaLabel: 'Aggiungi scadenza',
      onCta: onAdd,
    );
  }
}
