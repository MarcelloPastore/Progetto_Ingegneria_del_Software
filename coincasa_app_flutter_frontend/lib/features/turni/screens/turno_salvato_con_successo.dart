import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/coinquilini_notified_banner.dart';

class TurnoSaveResultArguments {
  const TurnoSaveResultArguments({required this.isEditing});

  final bool isEditing;
}

class TurnoSalvatoConSuccessoScreen extends StatelessWidget {
  const TurnoSalvatoConSuccessoScreen({super.key});

  static const routeName = '/turni/successo';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final isEditing = args is TurnoSaveResultArguments
        ? args.isEditing
        : args == true;

    return _TurnoSuccessScaffold(
      title: isEditing ? 'Turno aggiornato!' : 'Turno salvato!',
      description: isEditing
          ? 'Hai aggiornato il turno con successo.\n'
                'Le modifiche sono state applicate\n'
                'alla programmazione corrente.'
          : 'Hai salvato il turno con successo. Il\n'
                'responsabile viene assegnato\n'
                'automaticamente in rotazione e i turni\n'
                'successivi restano invariati.',
      onReturn: () => Navigator.of(context).pushReplacementNamed('/turni'),
    );
  }
}

class _TurnoSuccessScaffold extends StatelessWidget {
  const _TurnoSuccessScaffold({
    required this.title,
    required this.description,
    required this.onReturn,
  });

  final String title;
  final String description;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p24,
            AppSizes.p60,
            AppSizes.p24,
            AppSizes.p32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/Icons/green_check_mark.png',
                width: AppSizes.p110,
                height: AppSizes.p110,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: AppSizes.p35),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  fontSize: AppSizes.p25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSizes.p56),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: AppSizes.p19,
                  height: 1.16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p56),
              const CoinquiliniNotifiedBanner(),
              const SizedBox(height: AppSizes.p18),
              _PurpleActionButton(
                label: 'Ritorna ai turni',
                onPressed: onReturn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurpleActionButton extends StatefulWidget {
  const _PurpleActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PurpleActionButton> createState() => _PurpleActionButtonState();
}

class _PurpleActionButtonState extends State<_PurpleActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = AppColors.brandSecondary;
    const Color border = AppColors.brandPrimaryDark;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: AppSizes.p56,
        transform: Matrix4.diagonal3Values(
          _pressed ? 0.986 : 1.0,
          _pressed ? 0.986 : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(color: border, width: AppSizes.p2),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBackground.withValues(
                alpha: _pressed ? 0.18 : 0.32,
              ),
              blurRadius: _pressed ? 6 : 12,
              offset: Offset(0, _pressed ? 3 : 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
        child: Text(
          widget.label,
          style: AppTextStyles.buttonCompact.copyWith(
            color: AppColors.textOnDark,
            fontSize: AppSizes.p19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
