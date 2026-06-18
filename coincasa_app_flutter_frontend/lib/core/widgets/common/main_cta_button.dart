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
    final showActions = showDelete;

    if (!hasBack && !showActions) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showActions) ...[
            Row(
              children: [
                Expanded(
                  child: _DetailActionButton(
                    label: modifyLabel,
                    color: AppColors.problemPriorityMedium,
                    onPressed: isCreator ? onModify : null,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: _DetailActionButton(
                    label: deleteLabel,
                    color: AppColors.statusNegative,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
            if (hasBack) const SizedBox(height: AppSizes.p10),
          ],
          if (hasBack) MainCtaButton(label: backLabel!, onPressed: onBack),
        ],
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  static const _radius = BorderRadius.all(Radius.circular(AppSizes.radius12));

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final effectiveColor = isDisabled ? AppColors.textMuted : color;

    return SizedBox(
      height: AppSizes.p48,
      width: double.infinity,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: AppGradients.whiteOverlay(topAlpha: isDisabled ? 0.04 : 0.18),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: AppSizes.p2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: effectiveColor,
            ),
            borderRadius: _radius,
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p4,
              offset: Offset(0, AppSizes.p4),
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
                Icon(Icons.lock_outline_rounded, color: effectiveColor, size: AppSizes.p14),
                const SizedBox(width: AppSizes.p5),
              ],
              Text(
                label,
                style: AppTextStyles.buttonCompact.copyWith(color: effectiveColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class MainCtaColors {
  static const turni    = AppColors.statusInfo;
  static const spese    = AppColors.warningSoft;
  static const scadenze = AppColors.statusNegative;
  static const problemi = AppColors.brandSecondary;
}

class MainCtaButton extends StatelessWidget {
  const MainCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = AppSizes.p52,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  static const _borderRadius = BorderRadius.all(Radius.circular(AppSizes.radius15));

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
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p6,
              offset: Offset(0, AppSizes.p3),
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
            elevation: AppSizes.p0,
            shadowColor: Colors.transparent,
          ),
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(color: AppColors.textOnDark),
          ),
        ),
      ),
    );
  }
}

class SecondaryCtaButton extends StatelessWidget {
  const SecondaryCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = AppSizes.p48,
    this.color = MainCtaColors.turni,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color color;

  static const _borderRadius = BorderRadius.all(Radius.circular(AppSizes.radius12));

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
          style: AppTextStyles.buttonCompact.copyWith(color: color),
        ),
      ),
    );
  }
}
