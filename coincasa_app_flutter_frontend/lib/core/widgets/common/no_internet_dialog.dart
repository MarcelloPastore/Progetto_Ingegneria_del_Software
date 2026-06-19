import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/config/env.dart';
import 'package:coincasa_app/core/widgets/common/app_cancel_button_primary.dart';

class NoInternetDialog {
  static bool isShowing = false;

  static void show() {
    if (isShowing) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    isShowing = true;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      barrierColor: AppColors.darkBackground.withAlpha(180),
      builder: (_) => const _NoInternetDialogContent(),
    ).whenComplete(() => isShowing = false);
  }
}

class _NoInternetDialogContent extends StatefulWidget {
  const _NoInternetDialogContent();

  @override
  State<_NoInternetDialogContent> createState() =>
      _NoInternetDialogContentState();
}

class _NoInternetDialogContentState extends State<_NoInternetDialogContent> {
  bool _isLoading = false;

  Future<void> _retry() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      final response = await Dio().get<void>(
        '${Env.baseUrl}/health',
        options: Options(receiveTimeout: const Duration(seconds: 4)),
      );
      if (response.statusCode == 200 && mounted) {
        Navigator.of(context).pop();
      } else {
        _showError();
      }
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(
          'Nessuna connessione. Riprova quando sei online.',
          style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.errorStrong,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p32,
        vertical: AppSizes.p40,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p24,
          AppSizes.p32,
          AppSizes.p24,
          AppSizes.p28,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius24),
          border: Border.all(
            color: AppColors.dividerDark,
            width: AppSizes.p1_2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WifiWarningIcon(),
            const SizedBox(height: AppSizes.p24),
            Text(
              'Nessuna connessione',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSizes.p12),
            Text(
              "Non è possibile completare\nl'operazione senza connessione a\ninternet",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMutedRelaxed.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textMutedSoft,
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            const _BulletList(
              items: [
                'I coinquilini non verranno avvisati',
                'Riprova quando sei connesso',
              ],
            ),
            const SizedBox(height: AppSizes.p28),
            SizedBox(
              width: double.infinity,
              height: AppSizes.p52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.errorStrong,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius20),
                  ),
                ),
                onPressed: _isLoading ? null : _retry,
                child: _isLoading
                    ? const SizedBox(
                        width: AppSizes.p24,
                        height: AppSizes.p24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textOnDark,
                          ),
                        ),
                      )
                    : Text(
                        'Riprova',
                        style: AppTextStyles.buttonCompact.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            AppCancelButtonPrimary(
              enabled: !_isLoading,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WifiWarningIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.p110,
      height: AppSizes.p90,
      decoration: BoxDecoration(
        gradient: AppGradients.wifiWarningBackground,
        borderRadius: BorderRadius.circular(AppSizes.radius18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppGradients.wifiWarningIcon.createShader(bounds),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: AppSizes.p56,
              color: AppColors.textOnDark,
            ),
          ),
          Positioned(
            bottom: AppSizes.p8,
            right: AppSizes.p10,
            child: Container(
              width: AppSizes.p26,
              height: AppSizes.p26,
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceDarkElevated,
                  width: AppSizes.p2,
                ),
              ),
              child: const Icon(
                Icons.warning_rounded,
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

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p14,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.dividerDark, width: AppSizes.p1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
                child: Row(
                  children: [
                    Container(
                      width: AppSizes.p10,
                      height: AppSizes.p10,
                      decoration: const BoxDecoration(
                        color: AppColors.errorStrong,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textMutedLight,
                          fontSize: AppSizes.p14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
