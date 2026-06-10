import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class DeassegnazioneSuccessoScreen extends StatelessWidget {
  const DeassegnazioneSuccessoScreen({super.key});

  static const String routeName = '/problemi/deassegnazione-successo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/problemi'),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.brandAccent,
                    size: 28,
                  ),
                ),
              ),
              const Spacer(),
              _SuccessCard(),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFC21A).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SuccessIcon(),
          const SizedBox(height: 24),
          const Text(
            'De-assegnazione\ncompletata',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Il problema è tornato allo stato Segnalato. Tutti i coinquilini sono stati avvisati e possono occuparsene',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _DetailsTable(),
          const SizedBox(height: 32),
          _TornaButton(),
        ],
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFF5D4037), // Brownish background
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.person_rounded,
            color: Color(0xFF64B5F6), // Blue person
            size: 60,
          ),
          Positioned(
            right: 18,
            top: 25,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFF75C6C),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5D4037), width: 2),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D293B),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _DetailRow(
            label: 'Nuovo stato',
            value: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF39B54A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF39B54A), width: 1),
              ),
              child: const Text(
                'Segnalato',
                style: TextStyle(
                  color: Color(0xFF39B54A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _DetailRow(
            label: 'Responsabile',
            value: Text(
              'Nessuno',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Coinquilini avvisati',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, color: Color(0xFF39B54A), size: 20),
                const SizedBox(width: 4),
                const Text(
                  'Si',
                  style: TextStyle(
                    color: Color(0xFF39B54A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        value,
      ],
    );
  }
}

class _TornaButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/problemi'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF5B7FFF), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Torna ai problemi',
          style: TextStyle(
            color: Color(0xFF5B7FFF),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
