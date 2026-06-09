import 'dart:async';
import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class AttesaInvioCodiceScreen extends StatefulWidget {
  const AttesaInvioCodiceScreen({super.key, this.email = 'marco@gmail.com'});

  final String email;

  @override
  State<AttesaInvioCodiceScreen> createState() =>
      _AttesaInvioCodiceScreenState();
}

class _AttesaInvioCodiceScreenState extends State<AttesaInvioCodiceScreen> {
  int _activeIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Avvia un timer che cambia il pallino attivo ogni 600ms
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          _activeIndex = (_activeIndex + 1) % 3;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = widget.email.trim().toLowerCase();

    return AuthRecoveryScaffold(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSizes.p78),
          const AuthRecoveryBadge(icon: AuthRecoveryBadgeIcon.email),
          const SizedBox(height: AppSizes.p19),
          const Text(
            'Invio in corso...',
            textAlign: TextAlign.center,
            style: AppTextStyles.strongTitle,
          ),
          const SizedBox(height: AppSizes.p11),
          Text(
            'Stiamo inviando il codice di ripristino a\n$normalizedEmail',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSizes.p48),
          RecoveryProgressDots(activeIndex: _activeIndex),
          const SizedBox(height: AppSizes.p48),
          const Text(
            'Questa operazione potrebbe richiedere qualche secondo',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong,
          ),
        ],
      ),
    );
  }
}
