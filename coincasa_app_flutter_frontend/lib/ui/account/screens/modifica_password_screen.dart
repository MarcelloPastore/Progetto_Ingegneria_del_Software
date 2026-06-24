import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_client.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/auth/auth_widgets.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/domain/viewmodel/account_view_model.dart';

class ModificaPasswordScreen extends ConsumerStatefulWidget {
  const ModificaPasswordScreen({super.key});

  static const routeName = '/account/modifica-password';

  @override
  ConsumerState<ModificaPasswordScreen> createState() =>
      _ModificaPasswordScreenState();
}

class _ModificaPasswordScreenState
    extends ConsumerState<ModificaPasswordScreen> {
  final _vecchiaController = TextEditingController();
  final _nuovaController = TextEditingController();
  final _confermaController = TextEditingController();

  bool _obscureVecchia = true;
  bool _obscureNuova = true;
  bool _obscureConferma = true;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _vecchiaController.dispose();
    _nuovaController.dispose();
    _confermaController.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    final vecchia = _vecchiaController.text;
    final nuova = _nuovaController.text;
    final conferma = _confermaController.text;

    if (vecchia.isEmpty || nuova.isEmpty || conferma.isEmpty) {
      setState(() => _errorMessage = 'Compila tutti i campi.');
      return;
    }
    if (nuova == vecchia) {
      setState(
        () => _errorMessage =
            'La nuova password non può coincidere con quella attuale.',
      );
      return;
    }
    if (nuova != conferma) {
      setState(
        () => _errorMessage =
            'Le password non coincidono. Controlla i dati e riprova.',
      );
      return;
    }
    if (nuova.length < 10) {
      setState(
        () =>
            _errorMessage = 'La nuova password deve avere almeno 10 caratteri.',
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      await ref
          .read(accountViewModelProvider.notifier)
          .patchPassword(oldPassword: vecchia, newPassword: nuova);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 401
          ? 'La password attuale non è corretta.'
          : 'Modifica non riuscita. Riprova.';
      setState(() {
        _errorMessage = msg;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Modifica non riuscita. Riprova.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: AppTheme.darkTheme,
        child: Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSizes.pageHorizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSizes.p14),
                        AuthBackHeader(
                          title: 'Gestione account',
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: AppSizes.p35),
                        const Center(
                          child: AuthRecoveryBadge(
                            icon: AuthRecoveryBadgeIcon.lock,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p42),
                        const Text(
                          'Imposta nuova password',
                          style: AppTextStyles.strongTitle,
                        ),
                        const SizedBox(height: AppSizes.p10),
                        const Text(
                          'Scegli una nuova password per il tuo\naccount.',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: AppSizes.p32),

                        if (_errorMessage != null) ...[
                          AuthErrorBanner(message: _errorMessage!),
                          const SizedBox(height: AppSizes.p28),
                        ],

                        AuthField(
                          label: 'Vecchia password',
                          hint: '••••••••',
                          obscureText: _obscureVecchia,
                          labelBottomSpacing: 0,
                          controller: _vecchiaController,
                          hasError: _errorMessage != null,
                          suffixIcon: AuthPasswordToggle(
                            compact: true,
                            obscured: _obscureVecchia,
                            onTap: () => setState(
                              () => _obscureVecchia = !_obscureVecchia,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.p8),
                        AuthField(
                          label: 'Nuova password',
                          hint: '••••••••',
                          obscureText: _obscureNuova,
                          labelBottomSpacing: 0,
                          controller: _nuovaController,
                          hasError: _errorMessage != null,
                          suffixIcon: AuthPasswordToggle(
                            compact: true,
                            obscured: _obscureNuova,
                            onTap: () =>
                                setState(() => _obscureNuova = !_obscureNuova),
                          ),
                        ),
                        const SizedBox(height: AppSizes.p8),
                        AuthField(
                          label: 'Conferma nuova password',
                          hint: '••••••••',
                          obscureText: _obscureConferma,
                          labelBottomSpacing: 0,
                          controller: _confermaController,
                          hasError: _errorMessage != null,
                          suffixIcon: AuthPasswordToggle(
                            compact: true,
                            obscured: _obscureConferma,
                            onTap: () => setState(
                              () => _obscureConferma = !_obscureConferma,
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: AuthPrimaryButton(
                    text: _isSaving ? 'Salvataggio…' : 'Salva nuova password',
                    onPressed: _isSaving ? null : _salva,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 52, 24),
                  child: AppCancelButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
