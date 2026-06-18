import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/config/env.dart';

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
      barrierColor: Colors.black.withAlpha(180),
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
      await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      // Verify also that our server is reachable
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
      const SnackBar(
        content: Text(
          'Nessuna connessione. Riprova quando sei online.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFFB72B2B),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1830),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF3A3553), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WifiWarningIcon(),
            const SizedBox(height: 24),
            const Text(
              'Nessuna connessione',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Non è possibile completare\nl'operazione senza connessione a\ninternet",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAFAEAE),
                fontSize: 15,
                height: 1.4,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _BulletList(
              items: const [
                'I coinquilini non verranno avvisati',
                'Riprova quando sei connesso',
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB72B2B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _isLoading ? null : _retry,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Riprova',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6E41D1), width: 2),
                  backgroundColor: const Color(0xFF141324),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Annulla',
                  style: TextStyle(
                    color: Color(0xFF996CFA),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
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
      width: 110,
      height: 90,
      decoration: BoxDecoration(
        gradient: AppGradients.wifiWarningBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppGradients.wifiWarningIcon.createShader(bounds),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 10,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1C1830), width: 2),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF251F3F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3553), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFFD0CEDC),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
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
