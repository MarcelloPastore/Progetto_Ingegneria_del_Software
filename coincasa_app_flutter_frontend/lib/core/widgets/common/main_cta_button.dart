import 'package:flutter/material.dart';

// Blu usato da tutti i pulsanti CTA primari — colore unico, no color coding.
const _ctaBase   = Color(0xFF2B5CE6);
const _ctaTop    = Color(0xFF5A7EEE); // lerp white ~28%
const _ctaBottom = Color(0xFF2145B0); // lerp black ~22%

/// Colori per i pulsanti secondari (azioni contestuali come "Pareggia i conti").
abstract final class MainCtaColors {
  static const turni    = Color(0xFF5BADFF);
  static const spese    = Color(0xFFFF9E45);
  static const scadenze = Color(0xFFFF5252);
  static const problemi = Color(0xFFB47FFF);
}

/// Pulsante CTA primario: gradiente blu solido + testo bianco.
/// Uguale in tutte le schermate.
class MainCtaButton extends StatelessWidget {
  const MainCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  static const _borderRadius = BorderRadius.all(Radius.circular(15));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_ctaTop, _ctaBase, _ctaBottom],
            stops: [0.0, 0.60, 1.0],
          ),
          shape: RoundedRectangleBorder(borderRadius: _borderRadius),
          shadows: [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsante CTA secondario: sfondo trasparente + bordo colorato + testo colorato.
/// Mostra automaticamente una freccia ↗ in coda alla label.
class SecondaryCtaButton extends StatelessWidget {
  const SecondaryCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 48,
    this.color = MainCtaColors.turni,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color color;

  static const _borderRadius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: color, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '$label ↗',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
