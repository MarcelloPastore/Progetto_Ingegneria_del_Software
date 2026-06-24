import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class DeassegnazioneSuccessoScreen extends StatelessWidget {
  const DeassegnazioneSuccessoScreen({super.key});

  static const String routeName = '/problemi/deassegnazione-successo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p20,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/problemi'),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.brandAccent,
                    size: AppSizes.p28,
                  ),
                ),
              ),
              const Spacer(),
              const _SuccessCard(),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.p24),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: AppSizes.p20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SuccessIcon(),
          const SizedBox(height: AppSizes.p24),
          Text(
            'De-assegnazione\ncompletata',
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppSizes.p26,
              fontWeight: FontWeight.w900,
              height: AppSizes.p1_1,
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            'Il problema è tornato allo stato Segnalato. Tutti i coinquilini sono stati avvisati e possono occuparsene',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMutedRelaxed.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
              fontSize: AppSizes.p16,
              fontWeight: FontWeight.w500,
              height: AppSizes.p1_4,
            ),
          ),
          const SizedBox(height: AppSizes.p32),
          _DetailsTable(),
          const SizedBox(height: AppSizes.p32),
          _TornaButton(),
        ],
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            color: AppColors.statusInfo,
            size: AppSizes.p60,
          ),
          Positioned(
            right: AppSizes.p18,
            top: AppSizes.p25,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.p2),
              decoration: BoxDecoration(
                color: AppColors.statusNegative,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textOnDark,
                size: AppSizes.p14,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      padding: const EdgeInsets.all(AppSizes.p20),
      child: Column(
        children: [
          _DetailRow(
            label: 'Nuovo stato',
            value: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p10,
                vertical: AppSizes.p4,
              ),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radius12),
                border: Border.all(color: AppColors.statusSuccess, width: 1),
              ),
              child: Text(
                'Segnalato',
                style: TextStyle(
                  color: AppColors.statusSuccess,
                  fontSize: AppSizes.p13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          _DetailRow(
            label: 'Responsabile',
            value: Text(
              'Nessuno',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppSizes.p15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          _DetailRow(
            label: 'Coinquilini avvisati',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_rounded,
                  color: AppColors.statusSuccess,
                  size: AppSizes.p20,
                ),
                const SizedBox(width: AppSizes.p4),
                Text(
                  'Si',
                  style: TextStyle(
                    color: AppColors.statusSuccess,
                    fontSize: AppSizes.p15,
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: AppSizes.p15,
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
      height: AppSizes.p52,
      child: OutlinedButton(
        onPressed: () =>
            Navigator.of(context).pushReplacementNamed('/problemi'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.statusInfo, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
          ),
        ),
        child: Text(
          'Torna ai problemi',
          style: TextStyle(
            color: AppColors.statusInfo,
            fontSize: AppSizes.p18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
