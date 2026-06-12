import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/problemi/screens/problemi_home_screen.dart';

// ---------------------------------------------------------------------------
// Form state
// ---------------------------------------------------------------------------

enum _Priorita { urgent, medium, low }

@immutable
class _ModificaFormState {
  const _ModificaFormState({
    this.nome = '',
    this.descrizione = '',
    this.priorita,
    this.isSubmitting = false,
    this.showErrors = false,
    this.submitError,
  });

  final String nome;
  final String descrizione;
  final _Priorita? priorita;
  final bool isSubmitting;
  final bool showErrors;
  final String? submitError;

  bool get canSubmit =>
      nome.trim().isNotEmpty &&
      descrizione.trim().isNotEmpty &&
      priorita != null &&
      !isSubmitting;

  bool get hasNomeError => showErrors && nome.trim().isEmpty;
  bool get hasDescrizioneError => showErrors && descrizione.trim().isEmpty;
  bool get hasPrioritaError => showErrors && priorita == null;

  _ModificaFormState copyWith({
    String? nome,
    String? descrizione,
    _Priorita? priorita,
    bool? isSubmitting,
    bool? showErrors,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return _ModificaFormState(
      nome: nome ?? this.nome,
      descrizione: descrizione ?? this.descrizione,
      priorita: priorita ?? this.priorita,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showErrors: showErrors ?? this.showErrors,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
    );
  }
}

class _ModificaFormController extends StateNotifier<_ModificaFormState> {
  _ModificaFormController(Problema problema)
      : super(_ModificaFormState(
          nome: problema.titolo,
          descrizione: (problema.raw['descrizione'] as String?) ?? '',
          priorita: _parsePriorita(problema.priorita),
        ));

  static _Priorita? _parsePriorita(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('urg')) return _Priorita.urgent;
    if (lower.contains('med')) return _Priorita.medium;
    if (lower.contains('bass')) return _Priorita.low;
    return null;
  }

  void setNome(String v) => state = state.copyWith(nome: v, clearSubmitError: true);
  void setDescrizione(String v) => state = state.copyWith(descrizione: v, clearSubmitError: true);
  void setPriorita(_Priorita v) => state = state.copyWith(priorita: v, clearSubmitError: true);
  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  void setSubmitError(String msg) => state = state.copyWith(isSubmitting: false, submitError: msg, showErrors: true);

  bool validate() {
    state = state.copyWith(showErrors: true, clearSubmitError: true);
    return state.canSubmit;
  }
}

final _modificaFormProvider =
    StateNotifierProvider.autoDispose.family<_ModificaFormController, _ModificaFormState, Problema>(
  (ref, problema) => _ModificaFormController(problema),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ModificaProblemaScreen extends ConsumerStatefulWidget {
  const ModificaProblemaScreen({super.key});

  static const String routeName = '/problemi/modifica';

  @override
  ConsumerState<ModificaProblemaScreen> createState() => _ModificaProblemaScreenState();
}

class _ModificaProblemaScreenState extends ConsumerState<ModificaProblemaScreen> {
  final _nomeCtrl = TextEditingController();
  final _descrCtrl = TextEditingController();
  bool _initialized = false;
  late Problema _problema;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Problema) {
      _problema = args;
    } else {
      _problema = Problema(id: '', titolo: '', stato: 'Segnalato', priorita: 'Media', raw: {});
    }

    _nomeCtrl.text = _problema.titolo;
    _descrCtrl.text = (_problema.raw['descrizione'] as String?) ?? '';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descrCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final controller = ref.read(_modificaFormProvider(_problema).notifier);
    final form = ref.read(_modificaFormProvider(_problema));

    if (!controller.validate()) return;

    controller.setSubmitting(true);
    await Future.delayed(const Duration(milliseconds: 600));

    final prioritaStr = switch (form.priorita!) {
      _Priorita.urgent => 'Urgente',
      _Priorita.medium => 'Media',
      _Priorita.low => 'Bassa',
    };

    final index = mockProblemi.indexWhere((p) => p.id == _problema.id);
    if (index != -1) {
      mockProblemi[index] = Problema(
        id: _problema.id,
        titolo: form.nome.trim(),
        stato: _problema.stato,
        priorita: prioritaStr,
        raw: Map<String, dynamic>.from(_problema.raw)
          ..['descrizione'] = form.descrizione.trim(),
      );
    }

    if (mounted) {
      controller.setSubmitting(false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    final form = ref.watch(_modificaFormProvider(_problema));
    final ctrl = ref.read(_modificaFormProvider(_problema).notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.darkBackground,
          bottomNavigationBar: const HouseQuickNav(currentRoute: '/problemi'),
          body: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p20,
                AppSizes.p20,
                AppSizes.p20,
                AppSizes.p30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header back
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.brandAccent,
                      iconSize: 20,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      'Problemi',
                      style: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.brandAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSizes.p16),

                  // Title
                  Text(
                    'Modifica problema',
                    style: AppTextStyles.screenTitle.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Nome field
                  _FormTextField(
                    controller: _nomeCtrl,
                    hintText: 'Nome problema...',
                    hasError: form.hasNomeError,
                    maxLines: 1,
                    onChanged: ctrl.setNome,
                  ),
                  const SizedBox(height: AppSizes.p16),

                  // Descrizione field
                  _FormTextField(
                    controller: _descrCtrl,
                    hintText: 'Descrizione problema...',
                    hasError: form.hasDescrizioneError,
                    minLines: 4,
                    maxLines: 4,
                    onChanged: ctrl.setDescrizione,
                  ),
                  const SizedBox(height: AppSizes.p20),

                  // Priorità
                  Text(
                    'Priorità',
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.brandAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p10),
                  Row(children: [
                    Expanded(
                      child: _PriorityChip(
                        label: 'Urgente',
                        bgColor: const Color(0xFF710002),
                        dotColor: AppColors.problemPriorityUrgent,
                        selected: form.priorita == _Priorita.urgent,
                        onTap: () => ctrl.setPriorita(_Priorita.urgent),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: _PriorityChip(
                        label: 'Media',
                        bgColor: const Color(0xFF7E3B00),
                        dotColor: AppColors.problemPriorityMedium,
                        selected: form.priorita == _Priorita.medium,
                        onTap: () => ctrl.setPriorita(_Priorita.medium),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: _PriorityChip(
                        label: 'Bassa',
                        bgColor: const Color(0xFF786000),
                        dotColor: AppColors.problemPriorityLow,
                        selected: form.priorita == _Priorita.low,
                        onTap: () => ctrl.setPriorita(_Priorita.low),
                      ),
                    ),
                  ]),

                  // Error banner
                  if (form.showErrors && !form.canSubmit) ...[
                    const SizedBox(height: AppSizes.p14),
                    Row(children: [
                      const Icon(Icons.error_rounded, color: AppColors.errorStrong, size: 20),
                      const SizedBox(width: AppSizes.p6),
                      Expanded(
                        child: Text(
                          form.submitError ?? 'Dati mancanti: compila i campi necessari',
                          style: AppTextStyles.error.copyWith(
                            color: AppColors.errorStrong,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: AppSizes.p28),

                  // Submit
                  _SubmitButton(
                    label: 'Salva modifiche',
                    isLoading: form.isSubmitting,
                    enabled: form.showErrors ? form.canSubmit : true,
                    onPressed: () {
                      if (!form.showErrors) {
                        if (ctrl.validate()) _submit();
                      } else if (form.canSubmit) {
                        _submit();
                      }
                    },
                  ),
                  const SizedBox(height: AppSizes.p12),

                  // Annulla
                  _CancelButton(onPressed: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets (identici a segnala_problema_screen per coerenza visiva)
// ---------------------------------------------------------------------------

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.controller,
    required this.hintText,
    required this.hasError,
    required this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppColors.errorStrong : AppColors.primaryBorder;
    return Stack(
      children: [
        TextField(
          controller: controller,
          cursorColor: AppColors.brandAccent,
          style: AppTextStyles.input.copyWith(color: AppColors.textOnDark),
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceDarkElevated,
            hintText: hintText,
            hintStyle: AppTextStyles.inputHint.copyWith(
              color: AppColors.textMutedLight.withValues(alpha: 0.72),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p14,
              vertical: AppSizes.p14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              borderSide: BorderSide(color: borderColor, width: 1.6),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
        if (hasError)
          Positioned(
            top: AppSizes.p10,
            right: AppSizes.p12,
            child: Text('*', style: TextStyle(color: AppColors.errorStrong, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.bgColor,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(bgColor, Colors.white, 0.30)!,
        bgColor,
        Color.lerp(bgColor, Colors.black, 0.18)!,
      ],
      stops: const [0, 0.62, 1],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: selected ? AppColors.brandAccent : AppColors.darkBackground,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? Colors.black.withValues(alpha: 0.45) : AppColors.shadowStrong,
              blurRadius: selected ? 8 : 6,
              offset: Offset(0, selected ? 4 : 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: dotColor, size: 18),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && !isLoading;
    return Opacity(
      opacity: effectiveEnabled ? 1.0 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.brandAccent, AppColors.brandPrimary],
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              onTap: effectiveEnabled ? onPressed : null,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
                        ),
                      )
                    : Text(
                        label,
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSizes.radius15),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radius15),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.7), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              'Annulla',
              style: AppTextStyles.button.copyWith(
                color: AppColors.errorStrong,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
