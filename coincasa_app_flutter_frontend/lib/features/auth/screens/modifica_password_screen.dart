import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/services/session_manager.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class ModificaPasswordScreen extends StatefulWidget {
  const ModificaPasswordScreen({super.key});

  static const routeName = '/account/modifica-password';

  @override
  State<ModificaPasswordScreen> createState() => _ModificaPasswordScreenState();
}

class _ModificaPasswordScreenState extends State<ModificaPasswordScreen> {
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
    if (nuova.length < 8) {
      setState(
        () =>
            _errorMessage = 'La nuova password deve avere almeno 8 caratteri.',
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    // Backend non ancora disponibile: clear sessione e vai al login.
    await SessionManager.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Contenuto scrollabile ────────────────────────────────────
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

              // ── Pulsanti fissi in fondo ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                child: AuthPrimaryButton(
                  text: _isSaving ? 'Salvataggio…' : 'Salva nuova password',
                  onPressed: _isSaving ? null : _salva,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(52, 0, 52, 24),
                child: _AnnullaButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsante Annulla rosso (bordo + testo rosso, sfondo scuro)
// ---------------------------------------------------------------------------

class _AnnullaButton extends StatelessWidget {
  const _AnnullaButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _red = Color(0xFFFF0202);
  static const _radius = BorderRadius.all(Radius.circular(AppSizes.radius16));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: AppColors.errorContainerDark,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: _red,
            ),
            borderRadius: _radius,
          ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: _red,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: _radius),
          ),
          child: Text(
            'Annulla',
            style: AppTextStyles.buttonCompact.copyWith(color: _red),
          ),
        ),
      ),
    );
  }
}
