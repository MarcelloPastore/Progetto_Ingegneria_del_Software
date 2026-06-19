import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_cancel_button_primary.dart';

Future<void> showDeleteConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  required Future<void> Function() onConfirm,
  VoidCallback? onSuccess,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Chiudi',
    barrierColor: Colors.white.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, _) => _DeleteConfirmDialog(
      title: title,
      description: description,
      onConfirm: onConfirm,
      onSuccess: onSuccess,
    ),
  );
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({
    required this.title,
    required this.description,
    required this.onConfirm,
    this.onSuccess,
  });

  final String title;
  final String description;
  final Future<void> Function() onConfirm;
  final VoidCallback? onSuccess;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _handleConfirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Impossibile eliminare. Riprova.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.p28),
              padding: const EdgeInsets.fromLTRB(AppSizes.p32, AppSizes.p24, AppSizes.p32, AppSizes.p28),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkElevated,
                borderRadius: BorderRadius.circular(AppSizes.radius18),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowStrong,
                    blurRadius: AppSizes.p24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: AppSizes.p30,
                    backgroundColor: AppColors.error,
                    child: Icon(
                      Icons.delete_rounded,
                      color: AppColors.errorContainerStrong,
                      size: AppSizes.p34,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p18),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMutedRelaxed.copyWith(
                      color: AppColors.textMutedLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSizes.p12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.error.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: AppSizes.p24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _handleConfirm,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.errorStrong,
                          width: AppSizes.p2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: AppSizes.p22,
                              height: AppSizes.p22,
                              child: CircularProgressIndicator(
                                color: AppColors.errorStrong,
                                strokeWidth: 2.4,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Sì, elimina definitivamente',
                                style: AppTextStyles.buttonCompact.copyWith(
                                  color: AppColors.errorStrong,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p10),
                  AppCancelButtonPrimary(
                    enabled: !_loading,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
