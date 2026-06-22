import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/app_cancel_button.dart';
import 'package:coincasa_app/core/widgets/common/app_submit_button.dart';
import 'package:coincasa_app/core/widgets/common/app_text_field.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/app_priority_chip.dart';
import 'package:coincasa_app/core/widgets/common/section_label.dart';
import 'package:coincasa_app/domain/viewmodel/problemi_viewmodel.dart';
import 'package:coincasa_app/ui/problemi/screens/popup_successo_FAB.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _segnalaInquiliniProvider =
    FutureProvider.family<List<Inquilino>, String?>((ref, casaId) async {
      if (casaId == null || casaId.isEmpty) return const [];
      return ApiProvider.casa.listInquilini(casaId);
    });

// ---------------------------------------------------------------------------
// Form enums & state
// ---------------------------------------------------------------------------

enum _Priorita { urgent, medium, low }

enum _AssignmentMode { me, everyone }

@immutable
class _SegnalaFormState {
  const _SegnalaFormState({
    this.nome = '',
    this.descrizione = '',
    this.priorita = _Priorita.medium,
    this.assignmentMode = _AssignmentMode.everyone,
    this.isSubmitting = false,
    this.showErrors = false,
    this.submitError,
  });

  final String nome;
  final String descrizione;
  final _Priorita? priorita;
  final _AssignmentMode? assignmentMode;
  final bool isSubmitting;
  final bool showErrors;
  final String? submitError;

  bool get canSubmit =>
      nome.trim().isNotEmpty && descrizione.trim().isNotEmpty && !isSubmitting;

  bool get hasNomeError => showErrors && nome.trim().isEmpty;
  bool get hasDescrizioneError => showErrors && descrizione.trim().isEmpty;
  bool get hasAnyError => submitError != null || hasNomeError;

  _SegnalaFormState copyWith({
    String? nome,
    String? descrizione,
    _Priorita? priorita,
    bool clearPriorita = false,
    _AssignmentMode? assignmentMode,
    bool clearAssignment = false,
    bool? isSubmitting,
    bool? showErrors,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return _SegnalaFormState(
      nome: nome ?? this.nome,
      descrizione: descrizione ?? this.descrizione,
      priorita: clearPriorita ? null : priorita ?? this.priorita,
      assignmentMode: clearAssignment
          ? null
          : assignmentMode ?? this.assignmentMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showErrors: showErrors ?? this.showErrors,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
    );
  }
}

class _SegnalaFormController extends StateNotifier<_SegnalaFormState> {
  _SegnalaFormController() : super(const _SegnalaFormState());

  void setNome(String v) =>
      state = state.copyWith(nome: v, clearSubmitError: true);

  void setDescrizione(String v) =>
      state = state.copyWith(descrizione: v, clearSubmitError: true);

  void setPriorita(_Priorita v) =>
      state = state.copyWith(priorita: v, clearSubmitError: true);

  void setAssignment(_AssignmentMode v) =>
      state = state.copyWith(assignmentMode: v, clearSubmitError: true);

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

  void reset() => state = const _SegnalaFormState();
}

final _segnalaFormProvider =
    StateNotifierProvider.autoDispose<
      _SegnalaFormController,
      _SegnalaFormState
    >((ref) => _SegnalaFormController());

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SegnalaProblemaScreen extends ConsumerStatefulWidget {
  const SegnalaProblemaScreen({super.key});

  static const String routeName = '/problemi/segnala';

  @override
  ConsumerState<SegnalaProblemaScreen> createState() =>
      _SegnalaProblemaScreenState();
}

class _SegnalaProblemaScreenState extends ConsumerState<SegnalaProblemaScreen> {
  final _nomeCtrl = TextEditingController();
  final _descrCtrl = TextEditingController();

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descrCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = ref.read(_segnalaFormProvider);
    if (form.isSubmitting) return;

    final controller = ref.read(_segnalaFormProvider.notifier);
    if (!controller.validate()) return;

    FocusScope.of(context).unfocus();
    controller.setSubmitting(true);

    try {
      final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
      if (casaId.isEmpty) {
        controller.setSubmitError('Nessuna casa selezionata.');
        return;
      }

      final assigneeId = await _resolveAssigneeId(form.assignmentMode, casaId);
      if (form.assignmentMode == _AssignmentMode.me &&
          (assigneeId == null || assigneeId.isEmpty)) {
        controller.setSubmitError(
          'Non riesco a identificare l\'assegnatario corrente.',
        );
        return;
      }

      final autoAssegna =
          assigneeId != null &&
          assigneeId.isNotEmpty &&
          form.assignmentMode == _AssignmentMode.me;

      await ref
          .read(problemiViewModelProvider(casaId).notifier)
          .segnalaProblema(
            {
              'nome': form.nome.trim(),
              'descrizione': form.descrizione.trim(),
              'priorita': _priorityPayload(form.priorita!),
            },
            autoAssegna: autoAssegna,
          );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ProblemaSuccessoFABDialog(
            assignedToMe: form.assignmentMode == _AssignmentMode.me,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Errore creazione problema: $e');
      if (mounted) {
        controller.setSubmitError('Impossibile salvare il problema. Riprova.');
      }
    } finally {
      if (mounted) {
        controller.setSubmitting(false);
      }
    }
  }

  Future<String?> _resolveAssigneeId(
    _AssignmentMode? mode,
    String casaId,
  ) async {
    if (mode != _AssignmentMode.me) return null;
    final currentUserId = ApiProvider.client.currentUserId?.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) return currentUserId;
    final inquilini = await ref.read(_segnalaInquiliniProvider(casaId).future);
    return _resolveCurrentInquilino(inquilini)?.id;
  }

  Inquilino? _resolveCurrentInquilino(List<Inquilino> inquilini) {
    final currentId = ApiProvider.client.currentUserId?.trim();
    if (currentId != null && currentId.isNotEmpty) {
      for (final i in inquilini) {
        if (i.id.trim() == currentId) return i;
      }
    }
    final email = ApiProvider.client.currentUserEmail?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      for (final i in inquilini) {
        if (i.email.trim().toLowerCase() == email) return i;
      }
    }
    return null;
  }

  String _priorityPayload(_Priorita p) => switch (p) {
    _Priorita.urgent => 'Urgente',
    _Priorita.medium => 'Media',
    _Priorita.low => 'Bassa',
  };

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(_segnalaFormProvider);
    final ctrl = ref.read(_segnalaFormProvider.notifier);
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
                  Text(
                    'Segnala problema',
                    style: AppTextStyles.screenTitle.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: AppSizes.p26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Nome field
                  AppTextField(
                    controller: _nomeCtrl,
                    label: 'Nome problema',
                    hintText: 'Nome problema...',
                    hasError: form.hasNomeError,
                    showRequired: true,
                    maxLines: 1,
                    onChanged: ctrl.setNome,
                    errorText:
                        form.hasNomeError ? 'Inserisci il nome' : null,
                  ),
                  const SizedBox(height: AppSizes.p16),

                  // Descrizione field
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
                  _PriorityRow(
                    selected: form.priorita,
                    onChanged: ctrl.setPriorita,
                  ),
                  const SizedBox(height: AppSizes.p24),

                  _AssigneeCard(
                    selected: form.assignmentMode,
                    onChanged: ctrl.setAssignment,
                  ),

                  if (form.hasAnyError) ...[
                    const SizedBox(height: AppSizes.p14),
                    _ErrorBanner(
                      message: form.submitError ??
                          'Dati mancanti: compila i campi necessari',
                    ),
                  ],

                  const SizedBox(height: AppSizes.p20),

                  AppSubmitButton(
                    label: form.showErrors && !form.canSubmit
                        ? 'Salva Problema'
                        : 'Segnala problema',
                    isLoading: form.isSubmitting,
                    enabled: form.showErrors ? form.canSubmit : true,
                    onPressed: () {
                      if (!form.showErrors) {
                        final valid = ctrl.validate();
                        if (valid) _submit();
                      } else if (form.canSubmit) {
                        _submit();
                      }
                    },
                  ),
                  const SizedBox(height: AppSizes.p12),

                  AppCancelButton(
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

// ---------------------------------------------------------------------------
// Priority row
// ---------------------------------------------------------------------------

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.selected, required this.onChanged});

  final _Priorita? selected;
  final ValueChanged<_Priorita> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppPriorityChip(
            label: 'Urgente',
            bgColor: AppColors.problemChipUrgentBg,
            dotColor: AppColors.problemPriorityUrgent,
            selected: selected == _Priorita.urgent,
            onTap: () => onChanged(_Priorita.urgent),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: AppPriorityChip(
            label: 'Media',
            bgColor: AppColors.problemChipMediumBg,
            dotColor: AppColors.problemPriorityMedium,
            selected: selected == _Priorita.medium,
            onTap: () => onChanged(_Priorita.medium),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: AppPriorityChip(
            label: 'Bassa',
            bgColor: AppColors.problemChipLowBg,
            dotColor: AppColors.problemPriorityLow,
            selected: selected == _Priorita.low,
            onTap: () => onChanged(_Priorita.low),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Assignee card
// ---------------------------------------------------------------------------

class _AssigneeCard extends StatelessWidget {
  const _AssigneeCard({required this.selected, required this.onChanged});

  final _AssignmentMode? selected;
  final ValueChanged<_AssignmentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p14,
        AppSizes.p12,
        AppSizes.p14,
        AppSizes.p16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.primaryBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chi se ne occupa?',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.warning,
              fontSize: AppSizes.p17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          _AssigneeButton(
            label: 'Assegna a me',
            icon: Icons.pan_tool_alt_rounded,
            fillColor: AppColors.turniAssignMeSurface,
            textColor: AppColors.statusPositive,
            borderColor: AppColors.statusPositive,
            selected: selected == _AssignmentMode.me,
            onTap: () => onChanged(_AssignmentMode.me),
          ),
          const SizedBox(height: AppSizes.p10),
          _AssigneeButton(
            label: 'Chiedi a tutti',
            icon: Icons.groups_rounded,
            fillColor: AppColors.turniAssigneeSurface,
            textColor: AppColors.warning,
            borderColor: AppColors.turniAssigneeBorder,
            selected: selected == _AssignmentMode.everyone,
            onTap: () => onChanged(_AssignmentMode.everyone),
          ),
        ],
      ),
    );
  }
}

class _AssigneeButton extends StatelessWidget {
  const _AssigneeButton({
    required this.label,
    required this.icon,
    required this.fillColor,
    required this.textColor,
    required this.borderColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fillColor;
  final Color textColor;
  final Color borderColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: AppSizes.p54,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(
            color: selected
                ? borderColor
                : AppColors.surfaceDarkElevated,
            width: selected ? 3 : AppSizes.p2_5,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: AppSizes.p24),
            const SizedBox(width: AppSizes.p8),
            Text(
              label,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: textColor,
                fontSize: AppSizes.p17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.error_rounded,
          color: AppColors.errorStrong,
          size: AppSizes.p20,
        ),
        const SizedBox(width: AppSizes.p6),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.error.copyWith(
              color: AppColors.errorStrong,
              fontSize: AppSizes.p14,
              fontStyle: FontStyle.italic,
              height: AppSizes.p1_3,
            ),
          ),
        ),
      ],
    );
  }
}
