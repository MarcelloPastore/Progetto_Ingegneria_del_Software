import 'package:flutter/material.dart';

Future<void> showEliminaCasaDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (_) => const EliminaCasaDialog(),
  );
}

class EliminaCasaDialog extends StatelessWidget {
  const EliminaCasaDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: const SingleChildScrollView(child: _DeleteCard()),
      ),
    );
  }
}

class _DeleteCard extends StatelessWidget {
  const _DeleteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF151127),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2243)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TrashBadge(),
          const SizedBox(height: 18),
          const Text(
            'Eliminare Casa Verdi?',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Questa azione e irreversibile. Verranno eliminati tutti i dati: spese, turni, scadenze, problemi e documenti. Tutti i coinquilini perderanno accesso.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFDAD6E7),
              fontSize: 17,
              height: 1.22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const _WarningBox(),
          const SizedBox(height: 20),
          _DeleteButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 14),
          _CancelButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _TrashBadge extends StatelessWidget {
  const _TrashBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 144,
        height: 144,
        decoration: BoxDecoration(
          color: const Color(0xFF4C2024),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFF2B45), width: 5),
        ),
        child: Center(
          child: Image.asset(
            'assets/Icons/62945wastebasket_109227 1.png',
            width: 88,
            height: 88,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF5B3F21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFA726), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFFC94D), size: 42),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hai 2 quote pendenti non saldate. Eliminando la casa non potranno piu essere recuperate.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF330808),
          foregroundColor: const Color(0xFFFF4D5E),
          side: const BorderSide(color: Color(0xFFFF243D), width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Si, elimina definitivamente',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2D215A),
          foregroundColor: const Color(0xFFD8B8FF),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF8A35FF), width: 2),
          ),
        ),
        child: const Text(
          'Annulla',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
