import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';


// ---------------------------------------------------------------------------
// Shared action bar for detail screens (Modifica / Elimina / Torna)
// ---------------------------------------------------------------------------

/// Barra azioni fissa in fondo alle schermate di dettaglio.
///
/// [isCreator] mostra il pulsante Modifica (e Elimina).
/// [canDelete] mostra solo il pulsante Elimina (per admin non creatori).
/// "Torna" è sempre visibile come [MainCtaButton].
class DetailActionsBar extends StatelessWidget {
  const DetailActionsBar({
    super.key,
    required this.modifyLabel,
    required this.deleteLabel,
    this.backLabel,
    this.onBack,
    this.onModify,
    this.onDelete,
    this.isCreator = false,
    this.canDelete = false,
  });

  final String modifyLabel;
  final String deleteLabel;
  final String? backLabel;
  final VoidCallback? onBack;
  final VoidCallback? onModify;
  final VoidCallback? onDelete;
  final bool isCreator;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final hasBack = backLabel != null && onBack != null;
    final showDelete = isCreator || canDelete;
    // Modifica è visibile ogni volta che c'è almeno un'azione disponibile,
    // ma abilitata solo per il creatore (altrimenti appare bloccata).
    final showActions = showDelete;

    if (!hasBack && !showActions) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showActions) ...[
            Row(
              children: [
                Expanded(
                  child: _DetailActionButton(
                    label: modifyLabel,
                    color: MainCtaColors.problemi,
                    onPressed: isCreator ? onModify : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailActionButton(
                    label: deleteLabel,
                    color: MainCtaColors.scadenze,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
            if (hasBack) const SizedBox(height: 10),
          ],
          if (hasBack) MainCtaButton(label: backLabel!, onPressed: onBack),
        ],
      ),
    );
  }
}

/// Bottone azione dettaglio (Modifica / Elimina) — stile "Paga Quota":
/// shimmer bianco + bordo colorato esterno + testo colorato, senza freccia.
class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  static const _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final effectiveColor = isDisabled ? const Color(0xFF5A5570) : color;

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: AppGradients.whiteOverlay(topAlpha: isDisabled ? 0.04 : 0.18),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: effectiveColor,
            ),
            borderRadius: _radius,
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: _radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDisabled) ...[
                Icon(Icons.lock_outline_rounded, color: effectiveColor, size: 14),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 15,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          gradient: AppGradients.blueCta,
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
