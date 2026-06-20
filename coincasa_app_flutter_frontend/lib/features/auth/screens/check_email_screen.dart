import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/features/auth/screens/login_screen.dart';

import '../../../core/widgets/auth/auth_widgets.dart';

class CheckEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const CheckEmailScreen({super.key, required this.email});

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  static const _pollInterval = Duration(seconds: 4);

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      try {
        final verified = await ref.read(authViewModelProvider.notifier).checkEmailVerificata(
          widget.email.trim().toLowerCase(),
        );
        if (verified && mounted) {
          _pollTimer?.cancel();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (_) {
        // ignora errori di rete: si riprova al prossimo tick
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = widget.email.trim().toLowerCase();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: AppSizes.page,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSizes.p60),

                          SvgPicture.asset(
                            'assets/Icons/check_email.svg',
                            width: AppSizes.p100,
                            height: AppSizes.p100,
                            placeholderBuilder: (context) => const SizedBox(
                              width: AppSizes.p100,
                              height: AppSizes.p100,
                            ),
                          ),

                          const SizedBox(height: AppSizes.p32),

                          const Text(
                            'Controlla la tua mail!',
                            style: AppTextStyles.screenTitle,
                          ),

                          const SizedBox(height: AppSizes.p16),

                          const Text(
                            'Abbiamo inviato un link di verifica a:',
                            style: AppTextStyles.bodyMuted,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: AppSizes.p24),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.p20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              border: Border.all(
                                color: AppColors.brandAccent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius16,
                              ),
                            ),
                            child: Text(
                              normalizedEmail,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.brandAccent,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: AppSizes.p48),

                          const Text(
                            "Clicca sul link nell'email per\nattivare il tuo account.\nPotrebbe richiedere qualche\nminuto.",
                            style: AppTextStyles.bodyMutedRelaxed,
                            textAlign: TextAlign.center,
                          ),

                          const Spacer(),

                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyMuted,
                              children: [
                                const TextSpan(text: "Email sbagliata? "),
                                TextSpan(
                                  text: 'Modifica',
                                  style: AppTextStyles.link.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSizes.p20),
                          const AuthPageDots(activeIndex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
