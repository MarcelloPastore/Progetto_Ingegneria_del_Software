import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:coincasa_app/core/config/env.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class NoConnectionScreen extends StatefulWidget {
  const NoConnectionScreen({super.key});

  static const String routeName = '/no-connection';
  static bool isShowing = false;

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    NoConnectionScreen.isShowing = true;
  }

  @override
  void dispose() {
    NoConnectionScreen.isShowing = false;
    super.dispose();
  }

  Future<void> _checkHealth() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Dio().get<void>(
        '${Env.baseUrl}/health',
        options: Options(receiveTimeout: const Duration(seconds: 4)),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showError();
      }
    } catch (_) {
      _showError();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Il server non è ancora raggiungibile. Riprova tra qualche minuto.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p30),
          child: Column(
            children: [
              const Spacer(),
              // Icon stack (Globe with gradient and a red circular X badge)
              Stack(
                alignment: Alignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.globeIcon.createShader(bounds),
                    child: const Icon(
                      Icons.language_rounded,
                      size: 150,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.darkBackground,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD32F2F), // Red matching theme
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p40),
              // Title text
              const Text(
                'Servizio\ntemporaneamente non disponibile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSizes.p24),
              // Description/Subtitle text
              const Text(
                'I nostri server stanno riscontrando problemi tecnici. Riprova tra qualche minuto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMutedSoft,
                  fontSize: 17,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Buttons
              Column(
                children: [
                  // Retry Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB72B2B), // Darker red matching screenshot
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _isLoading ? null : _checkHealth,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              'Riprova',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6E41D1), width: 2.0),
                        backgroundColor: const Color(0xFF141324), // Matches cancel button fill
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text(
                        'Annulla',
                        style: TextStyle(
                          color: Color(0xFF996CFA), // Purple/indigo matching cancel button text
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p40),
            ],
          ),
        ),
      ),
    );
  }
}
