import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/dashboard/open_problems_section.dart';
import 'package:coincasa_app/features/problemi/screens/popup_successo_FAB.dart';

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
  bool get hasPrioritaError => false;
  bool get hasAssignmentError => false;
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

  // -- Submit ---------------------------------------------------------------

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

      // Risolviamo l'id dell'assegnatario prima di procedere
      final assigneeId = await _resolveAssigneeId(form.assignmentMode, casaId);
      if (form.assignmentMode == _AssignmentMode.me &&
          (assigneeId == null || assigneeId.isEmpty)) {
        controller.setSubmitError(
          'Non riesco a identificare l\'assegnatario corrente.',
        );
        return;
      }

      final problema = await ApiProvider.problemi.create(casaId, {
        'nome': form.nome.trim(),
        'descrizione': form.descrizione.trim(),
        'priorita': _priorityPayload(form.priorita!),
      });

      if (assigneeId != null && assigneeId.isNotEmpty) {
        await ApiProvider.problemi.autoAssegna(casaId, problema.id);
      }

      ref.read(problemiRevisionProvider.notifier).state++;

      if (!mounted) return;

      final wasAssignedToMe = form.assignmentMode == _AssignmentMode.me;

      // Navighiamo verso la schermata di successo
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              ProblemaSuccessoFABDialog(assignedToMe: wasAssignedToMe),
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

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(_segnalaFormProvider);
    final ctrl = ref.read(_segnalaFormProvider.notifier);

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
                  // Title
                  Text(
                    'Segnala problema',
                    style: AppTextStyles.screenTitle.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Nome field
                  Row(
                    children: [
                      Text(
                        'Nome problema',
                        style: AppTextStyles.screenTitleStrong.copyWith(
                          color: AppColors.textMutedLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: AppColors.errorStrong,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p6),
                  _SegnalaTextField(
                    controller: _nomeCtrl,
                    hintText: 'Nome problema...',
                    hasError: form.hasNomeError,
                    maxLines: 1,
                    onChanged: ctrl.setNome,
                  ),
                  const SizedBox(height: AppSizes.p16),

                  // Descrizione field
                  _SegnalaTextField(
                    controller: _descrCtrl,
                    hintText: 'Descrizione problema...',
                    hasError: form.hasDescrizioneError,
                    minLines: 4,
                    maxLines: 4,
                    onChanged: ctrl.setDescrizione,
                  ),
                  const SizedBox(height: AppSizes.p20),

                  // Priorità section
                  _SectionLabel(
                    label: 'Priorità',
                    color: AppColors.brandAccent,
                  ),
                  const SizedBox(height: AppSizes.p10),
                  _PriorityRow(
                    selected: form.priorita,
                    onChanged: ctrl.setPriorita,
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Chi se ne occupa? card
                  _AssigneeCard(
                    hasError: form.hasAssignmentError,
                    selected: form.assignmentMode,
                    onChanged: ctrl.setAssignment,
                  ),

                  // Error banner
                  if (form.hasAnyError) ...[
                    const SizedBox(height: AppSizes.p14),
                    _SegnalaErrorBanner(message: _buildErrorMessage(form)),
                  ],

                  const SizedBox(height: AppSizes.p20),

                  // Submit button
                  _SubmitButton(
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

                  // Annulla button
                  _CancelButton(onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildErrorMessage(_SegnalaFormState form) {
    if (form.submitError != null) return form.submitError!;
    return 'Dati mancanti: compila i campi necessari';
  }
}

// ---------------------------------------------------------------------------
// Text field
// ---------------------------------------------------------------------------

class _SegnalaTextField extends StatelessWidget {
  const _SegnalaTextField({
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
    final borderColor = hasError
        ? AppColors.errorStrong
        : AppColors.primaryBorder;

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
            child: Text(
              '*',
              style: TextStyle(
                color: AppColors.errorStrong,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.screenTitleStrong.copyWith(
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Priority row & chip
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
          child: _PriorityChip(
            label: 'Urgente',
            bgColor: const Color(0xFF710002),
            contentColor: AppColors.problemPriorityUrgent,
            selected: selected == _Priorita.urgent,
            onTap: () => onChanged(_Priorita.urgent),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: _PriorityChip(
            label: 'Media',
            bgColor: const Color(0xFF7E3B00),
            contentColor: AppColors.problemPriorityMedium,
            selected: selected == _Priorita.medium,
            onTap: () => onChanged(_Priorita.medium),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: _PriorityChip(
            label: 'Bassa',
            bgColor: const Color(0xFF786000),
            contentColor: AppColors.problemPriorityLow,
            selected: selected == _Priorita.low,
            onTap: () => onChanged(_Priorita.low),
          ),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.bgColor,
    required this.contentColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color contentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightBg = Color.lerp(bgColor, Colors.white, 0.28)!;
    final darkBg = Color.lerp(bgColor, Colors.black, 0.18)!;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: selected
          ? [Color.lerp(bgColor, Colors.white, 0.50)!, bgColor, darkBg]
          : [brightBg, bgColor, darkBg],
      stops: const [0, 0.62, 1],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: selected ? 58 : 50,
        margin: EdgeInsets.symmetric(vertical: selected ? 0 : 4),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(
            color: selected ? contentColor : Colors.transparent,
            width: selected ? 2.5 : 0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: contentColor.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadowStrong,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              Icon(Icons.check_circle_rounded, color: contentColor, size: 16)
            else
              Icon(Icons.circle, color: contentColor, size: 12),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: selected ? 15 : 13,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: selected ? 0.3 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assignee card
// ---------------------------------------------------------------------------

class _AssigneeCard extends StatelessWidget {
  const _AssigneeCard({
    required this.hasError,
    required this.selected,
    required this.onChanged,
  });

  final bool hasError;
  final _AssignmentMode? selected;
  final ValueChanged<_AssignmentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.errorStrong
        : AppColors.primaryBorder;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p14,
            AppSizes.p12,
            AppSizes.p14,
            AppSizes.p16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chi se ne occupa?',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.warning,
                  fontSize: 17,
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
        ),
        if (hasError)
          Positioned(
            top: AppSizes.p10,
            right: AppSizes.p12,
            child: Text(
              '*',
              style: TextStyle(
                color: AppColors.errorStrong,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
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
        height: 54,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(
            color: selected ? borderColor : AppColors.surfaceDarkElevated,
            width: selected ? 3 : 2.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: AppSizes.p8),
            Text(
              label,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: textColor,
                fontSize: 17,
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

class _SegnalaErrorBanner extends StatelessWidget {
  const _SegnalaErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_rounded, color: AppColors.errorStrong, size: 20),
        const SizedBox(width: AppSizes.p6),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.error.copyWith(
              color: AppColors.errorStrong,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Submit button (purple gradient)
// ---------------------------------------------------------------------------

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
    final opacity = effectiveEnabled ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textOnDark,
                          ),
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

// ---------------------------------------------------------------------------
// Cancel button (outlined dark red)
// ---------------------------------------------------------------------------

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
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.7),
                width: 2,
              ),
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
