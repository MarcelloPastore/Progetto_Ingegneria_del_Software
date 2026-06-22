import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/app_cancel_button.dart';
import 'package:coincasa_app/core/widgets/common/app_priority_chip.dart';
import 'package:coincasa_app/core/widgets/common/app_submit_button.dart';
import 'package:coincasa_app/core/widgets/common/app_text_field.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/screen_back_header.dart';
import 'package:coincasa_app/core/widgets/common/section_label.dart';
import 'package:coincasa_app/domain/viewmodel/problemi_viewmodel.dart';

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
    : super(
        _ModificaFormState(
          nome: problema.titolo,
          descrizione: (problema.raw['descrizione'] as String?) ?? '',
          priorita: _parsePriorita(problema.priorita),
        ),
      );

  static _Priorita? _parsePriorita(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('urg')) return _Priorita.urgent;
    if (lower.contains('med')) return _Priorita.medium;
    if (lower.contains('bass')) return _Priorita.low;
    return null;
  }

  void setNome(String v) =>
      state = state.copyWith(nome: v, clearSubmitError: true);
  void setDescrizione(String v) =>
      state = state.copyWith(descrizione: v, clearSubmitError: true);
  void setPriorita(_Priorita v) =>
      state = state.copyWith(priorita: v, clearSubmitError: true);
  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  void setSubmitError(String msg) => state = state.copyWith(
    isSubmitting: false,
    submitError: msg,
    showErrors: true,
  );

  bool validate() {
    state = state.copyWith(showErrors: true, clearSubmitError: true);
    return state.canSubmit;
  }
}

final _modificaFormProvider = StateNotifierProvider.autoDispose
    .family<_ModificaFormController, _ModificaFormState, Problema>(
      (ref, problema) => _ModificaFormController(problema),
    );

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ModificaProblemaScreen extends ConsumerStatefulWidget {
  const ModificaProblemaScreen({super.key});

  static const String routeName = '/problemi/modifica';

  @override
  ConsumerState<ModificaProblemaScreen> createState() =>
      _ModificaProblemaScreenState();
}

class _ModificaProblemaScreenState
    extends ConsumerState<ModificaProblemaScreen> {
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
      _problema = Problema(
        id: '',
        titolo: '',
        stato: 'Segnalato',
        priorita: 'Media',
        raw: {},
      );
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

    final prioritaStr = switch (form.priorita!) {
      _Priorita.urgent => 'Urgente',
      _Priorita.medium => 'Media',
      _Priorita.low => 'Bassa',
    };

    try {
      if (_problema.id.isEmpty) {
        controller.setSubmitError('Problema non disponibile.');
        return;
      }
      final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
      if (casaId.isEmpty) {
        controller.setSubmitError('Nessuna casa selezionata.');
        return;
      }

      final updated = await ref
          .read(problemiViewModelProvider(casaId).notifier)
          .updateProblema(_problema.id, {
            'nome': form.nome.trim(),
            'descrizione': form.descrizione.trim(),
            'priorita': prioritaStr,
          });

      if (!mounted) return;
      controller.setSubmitting(false);
      Navigator.of(context).pop(updated);
    } catch (_) {
      controller.setSubmitError('Impossibile salvare le modifiche. Riprova.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    final form = ref.watch(_modificaFormProvider(_problema));
    final ctrl = ref.read(_modificaFormProvider(_problema).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                  ScreenBackHeader(
                    title: 'Problemi',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: AppSizes.p16),

                  Text(
                    'Modifica problema',
                    style: AppTextStyles.screenTitle.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: AppSizes.p26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),

                  AppTextField(
                    controller: _nomeCtrl,
                    label: 'Nome problema',
                    hintText: 'Nome problema...',
                    hasError: form.hasNomeError,
                    showRequired: true,
                    maxLines: 1,
                    onChanged: ctrl.setNome,
                    errorText: form.hasNomeError ? 'Inserisci il nome' : null,
                  ),
                  const SizedBox(height: AppSizes.p16),

                  AppTextField(
                    controller: _descrCtrl,
                    hintText: 'Descrizione problema...',
                    hasError: form.hasDescrizioneError,
                    minLines: 4,
                    maxLines: 4,
                    onChanged: ctrl.setDescrizione,
                    errorText: form.hasDescrizioneError
                        ? 'Inserisci una descrizione'
                        : null,
                  ),
                  const SizedBox(height: AppSizes.p20),

                  SectionLabel(
                    'Priorità',
                    color: AppColors.brandAccent,
                    fontSize: AppSizes.p20,
                  ),
                  const SizedBox(height: AppSizes.p10),
                  Row(
                    children: [
                      Expanded(
                        child: AppPriorityChip(
                          label: 'Urgente',
                          bgColor: AppColors.problemChipUrgentBg,
                          dotColor: AppColors.problemPriorityUrgent,
                          selected: form.priorita == _Priorita.urgent,
                          onTap: () => ctrl.setPriorita(_Priorita.urgent),
                        ),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: AppPriorityChip(
                          label: 'Media',
                          bgColor: AppColors.problemChipMediumBg,
                          dotColor: AppColors.problemPriorityMedium,
                          selected: form.priorita == _Priorita.medium,
                          onTap: () => ctrl.setPriorita(_Priorita.medium),
                        ),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: AppPriorityChip(
                          label: 'Bassa',
                          bgColor: AppColors.problemChipLowBg,
                          dotColor: AppColors.problemPriorityLow,
                          selected: form.priorita == _Priorita.low,
                          onTap: () => ctrl.setPriorita(_Priorita.low),
                        ),
                      ),
                    ],
                  ),

                  if (form.showErrors && !form.canSubmit) ...[
                    const SizedBox(height: AppSizes.p14),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_rounded,
                          color: AppColors.errorStrong,
                          size: AppSizes.p20,
                        ),
                        const SizedBox(width: AppSizes.p6),
                        Expanded(
                          child: Text(
                            form.submitError ??
                                'Dati mancanti: compila i campi necessari',
                            style: AppTextStyles.error.copyWith(
                              color: AppColors.errorStrong,
                              fontSize: AppSizes.p14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSizes.p28),

                  AppSubmitButton(
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

                  AppCancelButton(
                    onPressed: () => Navigator.of(context).maybePop(),
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
