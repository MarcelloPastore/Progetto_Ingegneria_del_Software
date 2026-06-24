import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:coincasa_app/core/config/env.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/app_cancel_button_primary.dart';

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
      SnackBar(
        content: Text(
          'Il server non è ancora raggiungibile. Riprova tra qualche minuto.',
          style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
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
              Stack(
                alignment: Alignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.globeIcon.createShader(bounds),
                    child: const Icon(
                      Icons.language_rounded,
                      size: AppSizes.p132,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  Positioned(
                    bottom: AppSizes.p8,
                    right: AppSizes.p8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.darkBackground,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(AppSizes.p4),
                      child: Container(
                        width: AppSizes.p42,
                        height: AppSizes.p42,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textOnDark,
                          size: AppSizes.p28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p40),
              Text(
                'Servizio\ntemporaneamente non disponibile',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle.copyWith(height: 1.25),
              ),
              const SizedBox(height: AppSizes.p24),
              Text(
                'I nostri server stanno riscontrando problemi tecnici. Riprova tra qualche minuto.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMutedLarge.copyWith(height: 1.35),
              ),
              const Spacer(),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.p58,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.errorStrong,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius24),
                        ),
                      ),
                      onPressed: _isLoading ? null : _checkHealth,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
                            )
                          : Text(
                              'Riprova',
                              style: AppTextStyles.button.copyWith(color: AppColors.textOnDark),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  AppCancelButtonPrimary(
                    enabled: !_isLoading,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
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
