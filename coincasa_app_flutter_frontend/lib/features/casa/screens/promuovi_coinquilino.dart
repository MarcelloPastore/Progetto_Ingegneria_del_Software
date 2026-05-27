import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

Future<void> showPromuoviCoinquilinoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x8C000000),
    builder: (_) => const PromuoviCoinquilinoDialog(),
  );
}

class PromuoviCoinquilinoDialog extends StatelessWidget {
  const PromuoviCoinquilinoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: const SingleChildScrollView(child: _PromotionCard()),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard();

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
          const _PromotionIcon(),
          const SizedBox(height: 26),
          const Text(
            'Promuovere Francesco?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Francesco P. otterra il ruolo Amministratore e potra gestire coinquilini turni e documenti. I permessi saranno attivi al suo prossimo accesso.',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Color(0xFFE0E3F2),
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          const _InfoNotice(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF43B83E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Si, promuovi Francesco',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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

class _PromotionIcon extends StatelessWidget {
  const _PromotionIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF5DCC17),
        border: Border.all(color: const Color(0xFFC7FF8C), width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x805DCC17), blurRadius: 0, spreadRadius: 5),
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.arrow_upward, color: Colors.white, size: 70),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF242B57),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9298D5), width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Color(0xFF74C9FF), size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Questa azione e reversibile. Un Amministratore puo essere declassato da un altro Amministratore.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
