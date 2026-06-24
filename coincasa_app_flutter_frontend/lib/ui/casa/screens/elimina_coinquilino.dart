import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

Future<void> showEliminaCoinquilinoDialog(
  BuildContext context, {
  required String nomeCoinquilino,
  required String iniziali,
  VoidCallback? onRimuovi,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x8C000000),
    builder: (_) => EliminaCoinquilinoDialog(
      nomeCoinquilino: nomeCoinquilino,
      iniziali: iniziali,
      onRimuovi: onRimuovi,
    ),
  );
}

class EliminaCoinquilinoDialog extends StatelessWidget {
  final String nomeCoinquilino;
  final String iniziali;
  final VoidCallback? onRimuovi;

  const EliminaCoinquilinoDialog({
    super.key,
    required this.nomeCoinquilino,
    required this.iniziali,
    this.onRimuovi,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: _EliminaCard(
            nomeCoinquilino: nomeCoinquilino,
            iniziali: iniziali,
            onRimuovi: onRimuovi,
          ),
        ),
      ),
    );
  }
}

class _EliminaCard extends StatelessWidget {
  final String nomeCoinquilino;
  final String iniziali;
  final VoidCallback? onRimuovi;

  const _EliminaCard({
    required this.nomeCoinquilino,
    required this.iniziali,
    this.onRimuovi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      decoration: BoxDecoration(
        color: const Color(0xFF171D3D),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarIcon(iniziali: iniziali),
          const SizedBox(height: 26),
          const Text(
            'Rimuovi coinquilino',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$nomeCoinquilino verrà rimosso dalla casa. '
            'Le quote resteranno visibili agli altri coinquilini',
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Color(0xFFE0E3F2),
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                onRimuovi?.call();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD12C3D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Rimuovi $nomeCoinquilino',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandAccent,
                side: const BorderSide(color: AppColors.brandAccent, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Annulla',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  final String iniziali;
  const _AvatarIcon({required this.iniziali});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3B456D),
        border: Border.all(color: const Color(0xFF5A3AE0), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          iniziali,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
