import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class TurnoSalvatoConSuccessoScreen extends StatelessWidget {
  const TurnoSalvatoConSuccessoScreen({super.key});

  static const routeName = '/turni/successo';

  @override
  Widget build(BuildContext context) {
    return _TurnoSuccessScaffold(
      title: 'Turno salvato!',
      description:
          'Hai salvato il turno con successo. Il\n'
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
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSizes.p56),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: 19,
                  height: 1.16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p56),
              const _NotifiedBanner(),
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
    const Color bg = Color(0xFF7B43FF);
    const Color border = Color(0xFF4C1DBF);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: AppSizes.p56,
        transform: Matrix4.identity()..scale(_pressed ? 0.986 : 1.0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(color: border, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.18 : 0.32),
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
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _NotifiedBanner extends StatelessWidget {
  const _NotifiedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.p56,
      alignment: Alignment.center,
     
      child: Text(
        'Tutti i coinquilini sono stati avvisati',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.statusPositive,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
