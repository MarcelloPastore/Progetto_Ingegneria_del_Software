import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/primary_button.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/problemi/screens/popup_successo_FAB.dart';

final _problemiCasaProvider = FutureProvider.family<Casa?, String?>((
  ref,
  selectedCasaId,
) async {
  final caseUtente = await ApiProvider.casa.list();
  if (caseUtente.isEmpty) {
    return null;
  }

  if (selectedCasaId != null && selectedCasaId.isNotEmpty) {
    for (final casa in caseUtente) {
      if (casa.id == selectedCasaId) {
        return casa;
      }
    }
  }

  return caseUtente.first;
});

final _problemiInquiliniProvider =
    FutureProvider.family<List<Inquilino>, String?>((ref, casaId) async {
      if (casaId == null || casaId.isEmpty) {
        return const [];
      }
      return ApiProvider.casa.listInquilini(casaId);
    });

final problemiCreateFormProvider =
    StateNotifierProvider.autoDispose<
      _ProblemiCreateFormController,
      _ProblemiCreateFormState
    >((ref) => _ProblemiCreateFormController());

Future<void> showProblemiScreenPrincipaleDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.darkBackground.withValues(alpha: 0.42),
    builder: (_) => Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSizes.p12),
        child: const Dialog(
          backgroundColor: AppColors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: AppSizes.p20,
            vertical: AppSizes.p12,
          ),
          child: ProblemiPopupPanel(
            useSafeArea: true,
            showTabs: true,
            showFrame: true,
          ),
        ),
      ),
    ),
  );
}

enum _ProblemaPriority { urgent, medium, low }

enum _ProblemaAssignmentMode { me, everyone }

@immutable
class _ProblemiCreateFormState {
  const _ProblemiCreateFormState({
    this.nome = '',
    this.descrizione = '',
    this.priorita,
    this.assignmentMode,
    this.isSubmitting = false,
    this.showErrors = false,
    this.submitError,
  });

  final String nome;
  final String descrizione;
  final _ProblemaPriority? priorita;
  final _ProblemaAssignmentMode? assignmentMode;
  final bool isSubmitting;
  final bool showErrors;
  final String? submitError;

  bool get canSubmit =>
      nome.trim().isNotEmpty &&
      descrizione.trim().isNotEmpty &&
      priorita != null &&
      assignmentMode != null &&
      !isSubmitting;

  bool get hasNomeError => showErrors && nome.trim().isEmpty;
  bool get hasDescrizioneError => showErrors && descrizione.trim().isEmpty;
  bool get hasPrioritaError => showErrors && priorita == null;
  bool get hasAssignmentError => showErrors && assignmentMode == null;
  bool get hasBannerError =>
      submitError != null ||
      hasNomeError ||
      hasDescrizioneError ||
      hasPrioritaError ||
      hasAssignmentError;

  _ProblemiCreateFormState copyWith({
    String? nome,
    String? descrizione,
    _ProblemaPriority? priorita,
    bool clearPriorita = false,
    _ProblemaAssignmentMode? assignmentMode,
    bool clearAssignmentMode = false,
    bool? isSubmitting,
    bool? showErrors,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return _ProblemiCreateFormState(
      nome: nome ?? this.nome,
      descrizione: descrizione ?? this.descrizione,
      priorita: clearPriorita ? null : priorita ?? this.priorita,
      assignmentMode: clearAssignmentMode
          ? null
          : assignmentMode ?? this.assignmentMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showErrors: showErrors ?? this.showErrors,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
    );
  }
}

class _ProblemiCreateFormController
    extends StateNotifier<_ProblemiCreateFormState> {
  _ProblemiCreateFormController() : super(const _ProblemiCreateFormState());

  void setNome(String value) {
    state = state.copyWith(nome: value, clearSubmitError: true);
  }

  void setDescrizione(String value) {
    state = state.copyWith(descrizione: value, clearSubmitError: true);
  }

  void setPriorita(_ProblemaPriority value) {
    state = state.copyWith(
      priorita: value,
      clearPriorita: false,
      clearSubmitError: true,
    );
  }

  void setAssignmentMode(_ProblemaAssignmentMode value) {
    state = state.copyWith(
      assignmentMode: value,
      clearAssignmentMode: false,
      clearSubmitError: true,
    );
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }

  void setSubmitError(String message) {
    state = state.copyWith(
      isSubmitting: false,
      submitError: message,
      showErrors: true,
    );
  }

  bool validateBeforeSubmit() {
    state = state.copyWith(showErrors: true, clearSubmitError: true);
    return state.canSubmit;
  }

  void reset() {
    state = const _ProblemiCreateFormState();
  }
}

class ProblemiScreen extends StatelessWidget {
  const ProblemiScreen({super.key});

  static const String routeName = '/problemi';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.pageBackground,
      bottomNavigationBar: HouseQuickNav(currentRoute: '/problemi'),
      body: Center(
        child: ProblemiPopupPanel(
          useSafeArea: true,
          showTabs: true,
          showFrame: true,
        ),
      ),
    );
  }
}

class ProblemiPopupPanel extends ConsumerStatefulWidget {
  const ProblemiPopupPanel({
    super.key,
    required this.useSafeArea,
    this.showTabs = true,
    this.showFrame = true,
    this.showHeader = true,
  });

  final bool useSafeArea;
  final bool showTabs;
  final bool showFrame;
  final bool showHeader;

  @override
  ConsumerState<ProblemiPopupPanel> createState() => _ProblemiPopupPanelState();
}

class _ProblemiPopupPanelState extends ConsumerState<ProblemiPopupPanel> {
  final _nomeController = TextEditingController();
  final _descrizioneController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final controller = ref.read(problemiCreateFormProvider.notifier);
    final form = ref.read(problemiCreateFormProvider);
    final activeCasaController = ActiveCasaScope.of(context);
    final casa = await ref.read(
      _problemiCasaProvider(activeCasaController.selectedCasaId).future,
    );

    if (!controller.validateBeforeSubmit()) {
      return;
    }

    if (casa == null || casa.id.isEmpty) {
      controller.setSubmitError('Nessuna casa disponibile.');
      return;
    }

    final assigneeId = await _resolveAssigneeId(form.assignmentMode, casa.id);
    if (form.assignmentMode == _ProblemaAssignmentMode.me &&
        (assigneeId == null || assigneeId.isEmpty)) {
      controller.setSubmitError(
        'Non riesco a identificare l assegnatario corrente.',
      );
      return;
    }

    controller.setSubmitting(true);
    try {
      await ApiProvider.problemi.create(casa.id, {
        'nome': form.nome.trim(),
        'descrizione': form.descrizione.trim(),
        'priorita': _priorityPayload(form.priorita!),
        if (assigneeId != null && assigneeId.isNotEmpty)
          'assegnatario': assigneeId,
      });

      if (!mounted) {
        return;
      }

      controller.reset();
      _nomeController.clear();
      _descrizioneController.clear();

      await showProblemaSuccessoFABDialog(
        context,
        assignedToMe: form.assignmentMode == _ProblemaAssignmentMode.me,
      );
    } catch (_) {
      controller.setSubmitError('Impossibile salvare il problema. Riprova.');
    } finally {
      if (mounted) {
        controller.setSubmitting(false);
      }
    }
  }

  Future<String?> _resolveAssigneeId(
    _ProblemaAssignmentMode? assignmentMode,
    String casaId,
  ) async {
    if (assignmentMode != _ProblemaAssignmentMode.me) {
      return null;
    }

    final currentUserId = ApiProvider.client.currentUserId?.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }

    final inquilini = await ref.read(_problemiInquiliniProvider(casaId).future);
    final currentById = _resolveCurrentInquilino(inquilini);
    return currentById?.id;
  }

  Inquilino? _resolveCurrentInquilino(List<Inquilino> inquilini) {
    final currentId = ApiProvider.client.currentUserId?.trim();
    if (currentId != null && currentId.isNotEmpty) {
      for (final inquilino in inquilini) {
        if (inquilino.id.trim() == currentId) {
          return inquilino;
        }
      }
    }

    final currentEmail = ApiProvider.client.currentUserEmail
        ?.trim()
        .toLowerCase();
    if (currentEmail != null && currentEmail.isNotEmpty) {
      for (final inquilino in inquilini) {
        if (inquilino.email.trim().toLowerCase() == currentEmail) {
          return inquilino;
        }
      }
    }

    final currentDisplayName = ApiProvider.client.currentUserDisplayName
        ?.trim()
        .toLowerCase();
    if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
      for (final inquilino in inquilini) {
        final values = <String>{
          inquilino.nomeCompleto.trim().toLowerCase(),
          inquilino.nome.trim().toLowerCase(),
          inquilino.username.trim().toLowerCase(),
        };
        if (values.contains(currentDisplayName)) {
          return inquilino;
        }
      }
    }

    return null;
  }

  String _priorityPayload(_ProblemaPriority priority) {
    return switch (priority) {
      _ProblemaPriority.urgent => 'Urgente',
      _ProblemaPriority.medium => 'Media',
      _ProblemaPriority.low => 'Bassa',
    };
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.of(context);
    final form = ref.watch(problemiCreateFormProvider);
    final controller = ref.read(problemiCreateFormProvider.notifier);
    final casaAsync = ref.watch(
      _problemiCasaProvider(activeCasaController.selectedCasaId),
    );
    final casaName = casaAsync.maybeWhen(
      data: (casa) => casa?.nome.isNotEmpty == true ? casa!.nome : 'Casa',
      orElse: () => 'Casa',
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          _ProblemiHeader(casaName: casaName),
          const SizedBox(height: AppSizes.p14),
        ],
        if (widget.showFrame)
          _ProblemsFrame(
            child: _ProblemiFormContent(
              form: form,
              controller: controller,
              nomeController: _nomeController,
              descrizioneController: _descrizioneController,
              onSubmit: _submit,
              onRouteSelected: (route) {
                if (route == '/problemi') {
                  return;
                }
                Navigator.of(context).pushReplacementNamed(route);
              },
              onCancel: () {
                Navigator.of(context).pop();
              },
              showTabs: widget.showTabs,
              resolveBannerText: _resolveBannerText,
            ),
          )
        else
          _ProblemiFormContent(
            form: form,
            controller: controller,
            nomeController: _nomeController,
            descrizioneController: _descrizioneController,
            onSubmit: _submit,
            onRouteSelected: (route) {
              if (route == '/problemi') {
                return;
              }
              Navigator.of(context).pushReplacementNamed(route);
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
            showTabs: widget.showTabs,
            resolveBannerText: _resolveBannerText,
          ),
      ],
    );

    final panel = AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: widget.showFrame
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : 367.0;
                  final maxHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 640.0;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      4,
                      AppSizes.p10,
                      4,
                      AppSizes.p12,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: maxWidth,
                        maxWidth: maxWidth,
                        minHeight: maxHeight - AppSizes.p12,
                      ),
                      child: body,
                    ),
                  );
                },
              )
            : body,
      ),
    );

    return widget.useSafeArea ? SafeArea(child: panel) : panel;
  }

  String _resolveBannerText(_ProblemiCreateFormState form) {
    if (form.submitError != null) {
      return form.submitError!;
    }

    final errors = <String>[];
    if (form.hasNomeError) {
      errors.add('nome del problema');
    }
    if (form.hasDescrizioneError) {
      errors.add('descrizione');
    }
    if (form.hasPrioritaError) {
      errors.add('priorità');
    }
    if (form.hasAssignmentError) {
      errors.add('assegnazione');
    }

    if (errors.isEmpty) {
      return 'Dati mancanti: compila i campi necessari';
    }

    return 'Dati mancanti: compila ${errors.join(', ')}';
  }
}

class _ProblemiFormContent extends StatelessWidget {
  const _ProblemiFormContent({
    required this.form,
    required this.controller,
    required this.nomeController,
    required this.descrizioneController,
    required this.onSubmit,
    required this.onRouteSelected,
    required this.showTabs,
    required this.onCancel,
    required this.resolveBannerText,
  });

  final _ProblemiCreateFormState form;
  final _ProblemiCreateFormController controller;
  final TextEditingController nomeController;
  final TextEditingController descrizioneController;
  final VoidCallback onSubmit;
  final ValueChanged<String> onRouteSelected;
  final bool showTabs;
  final VoidCallback onCancel;
  final String Function(_ProblemiCreateFormState form) resolveBannerText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTabs) ...[
          _ProblemTabs(
            selectedRoute: '/problemi',
            onRouteSelected: onRouteSelected,
          ),
          const SizedBox(height: AppSizes.p18),
        ],
        Text(
          'Nuovo Problema',
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.brandPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSizes.p18),
        _ProblemTextField(
          controller: nomeController,
          hintText: 'Nome problema...',
          hasError: form.hasNomeError,
          errorText: form.hasNomeError
              ? 'Inserisci il nome del problema'
              : null,
          maxLines: 1,
          onChanged: controller.setNome,
        ),
        const SizedBox(height: AppSizes.p2),
        _ProblemTextField(
          controller: descrizioneController,
          hintText: 'Descrizione problema...',
          hasError: form.hasDescrizioneError,
          errorText: form.hasDescrizioneError
              ? 'Descrivi il problema in modo chiaro'
              : null,
          maxLines: 4,
          minLines: 4,
          onChanged: controller.setDescrizione,
        ),
        const SizedBox(height: AppSizes.p2),
        _SectionTitle(
          title: 'Priorità',
          hasError: form.hasPrioritaError,
          textColor: AppColors.brandSecondary,
        ),
        const SizedBox(height: AppSizes.p2),
        _PriorityRow(
          hasError: form.hasPrioritaError,
          selected: form.priorita,
          onChanged: controller.setPriorita,
        ),
        const SizedBox(height: AppSizes.p18),
        _AssigneeSection(
          hasError: form.hasAssignmentError,
          selected: form.assignmentMode,
          onChanged: controller.setAssignmentMode,
        ),
        if (form.hasBannerError) ...[
          const SizedBox(height: AppSizes.p12),
          _ErrorBanner(message: resolveBannerText(form)),
        ],
        const SizedBox(height: AppSizes.p16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p2),
          child: PrimaryButton(
            label: 'Segnala problema',
            isLoading: form.isSubmitting,
            onPressed: form.canSubmit ? onSubmit : null,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p28),
          child: OutlinedButton(
            onPressed: form.isSubmitting ? null : onCancel,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.errorContainerStrong,
              foregroundColor: AppColors.errorStrong,
              side: const BorderSide(color: AppColors.errorStrong, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Annulla',
              style: AppTextStyles.buttonCompact.copyWith(
                color: AppColors.errorStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProblemiHeader extends StatelessWidget {
  const _ProblemiHeader({required this.casaName});

  final String casaName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UserAvatar(
          radius: 23,
          userId: ApiProvider.client.currentUserAvatarSeed,
          username: ApiProvider.client.currentUserUsername,
          borderColor: AppColors.primaryBorder,
          borderWidth: 1.5,
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Text(
            casaName,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.brandTitle.copyWith(
              color: AppColors.brandAccent.withValues(alpha: 0.78),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.brandAccent.withValues(alpha: 0.70),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryBorder, width: 1.2),
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: AppColors.textOnDark,
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _ProblemsFrame extends StatelessWidget {
  const _ProblemsFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p10,
        AppSizes.p10,
        AppSizes.p10,
        AppSizes.p14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: AppColors.primaryBorder, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProblemTabs extends StatelessWidget {
  const _ProblemTabs({
    required this.selectedRoute,
    required this.onRouteSelected,
  });

  final String selectedRoute;
  final ValueChanged<String> onRouteSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.turniTabSurface,
        borderRadius: BorderRadius.circular(AppSizes.radius15),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Spesa',
            route: '/spese',
            selectedRoute: selectedRoute,
            onTap: onRouteSelected,
          ),
          _TabItem(
            label: 'Problema',
            route: '/problemi',
            selectedRoute: selectedRoute,
            onTap: onRouteSelected,
          ),
          _TabItem(
            label: 'Turno',
            route: '/turni',
            selectedRoute: selectedRoute,
            onTap: onRouteSelected,
          ),
          _TabItem(
            label: 'Scadenza',
            route: '/scadenze',
            selectedRoute: selectedRoute,
            onTap: onRouteSelected,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.route,
    required this.selectedRoute,
    required this.onTap,
  });

  final String label;
  final String route;
  final String selectedRoute;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = route == selectedRoute;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(route),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.brandAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: selected
                    ? AppColors.textOnDark
                    : AppColors.textMutedDark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.hasError,
    this.textColor,
  });

  final String title;
  final bool hasError;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final color = hasError
        ? AppColors.errorStrong
        : (textColor ?? AppColors.brandAccent);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (hasError)
          Text(
            '*',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _ProblemTextField extends StatelessWidget {
  const _ProblemTextField({
    required this.controller,
    required this.hintText,
    required this.hasError,
    required this.onChanged,
    this.errorText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final bool hasError;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.errorStrong
        : AppColors.primaryBorder;

    return TextField(
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
        helperText: errorText ?? ' ',
        helperStyle: AppTextStyles.fieldError.copyWith(
          color: hasError ? AppColors.errorStrong : AppColors.textMutedDark,
          fontSize: hasError ? 12 : 11,
        ),
        suffixIcon: hasError
            ? const Padding(
                padding: EdgeInsets.only(right: AppSizes.p12),
                child: Icon(
                  Icons.priority_high_rounded,
                  color: AppColors.errorStrong,
                  size: 22,
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          borderSide: const BorderSide(color: AppColors.errorStrong, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          borderSide: const BorderSide(color: AppColors.errorStrong, width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.hasError,
    required this.selected,
    required this.onChanged,
  });

  final bool hasError;
  final _ProblemaPriority? selected;
  final ValueChanged<_ProblemaPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.errorStrong
        : AppColors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radius15),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PriorityChip(
              label: 'Urgente',
              color: const Color(0xFF710002),
              contentColor: AppColors.problemPriorityUrgent,
              selected: selected == _ProblemaPriority.urgent,
              onTap: () => onChanged(_ProblemaPriority.urgent),
            ),
          ),
          const SizedBox(width: AppSizes.p6),
          Expanded(
            child: _PriorityChip(
              label: 'Media',
              color: const Color(0xFF7E3B00),
              contentColor: AppColors.problemPriorityMedium,
              selected: selected == _ProblemaPriority.medium,
              onTap: () => onChanged(_ProblemaPriority.medium),
            ),
          ),
          const SizedBox(width: AppSizes.p6),
          Expanded(
            child: _PriorityChip(
              label: 'Bassa',
              color: const Color(0xFF786000),
              contentColor: AppColors.problemPriorityLow,
              selected: selected == _ProblemaPriority.low,
              onTap: () => onChanged(_ProblemaPriority.low),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.color,
    required this.contentColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color contentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(color, Colors.white, 0.30)!,
        color,
        Color.lerp(color, Colors.black, 0.18)!,
      ],
      stops: const [0, 0.62, 1],
    );

    final borderColor = selected
        ? AppColors.brandAccent
        : AppColors.surfaceTint;
    final borderWidth = 3.5;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          gradient: background,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.black.withValues(alpha: 0.45)
                  : AppColors.shadowStrong,
              blurRadius: selected ? 8 : 6,
              offset: Offset(0, selected ? 4 : 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: contentColor, size: 18),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: contentColor,
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

class _AssigneeSection extends StatelessWidget {
  const _AssigneeSection({
    required this.hasError,
    required this.selected,
    required this.onChanged,
  });

  final bool hasError;
  final _ProblemaAssignmentMode? selected;
  final ValueChanged<_ProblemaAssignmentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.errorStrong
        : AppColors.primaryBorder;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p12,
        AppSizes.p12,
        AppSizes.p12,
        AppSizes.p14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title: 'Chi se ne occupa?', hasError: hasError),
          const SizedBox(height: AppSizes.p10),
          _AssigneeChoiceButton(
            label: 'Assegna a me',
            icon: Icons.pan_tool_alt_rounded,
            fillColor: AppColors.turniAssignMeSurface,
            textColor: AppColors.statusPositive,
            borderColor: AppColors.statusPositive,
            selected: selected == _ProblemaAssignmentMode.me,
            onTap: () => onChanged(_ProblemaAssignmentMode.me),
          ),
          const SizedBox(height: AppSizes.p10),
          _AssigneeChoiceButton(
            label: 'Chiedi a tutti',
            icon: Icons.groups_rounded,
            fillColor: AppColors.turniAssigneeSurface,
            textColor: AppColors.warning,
            borderColor: AppColors.turniAssigneeBorder,
            selected: selected == _ProblemaAssignmentMode.everyone,
            onTap: () => onChanged(_ProblemaAssignmentMode.everyone),
          ),
        ],
      ),
    );
  }
}

class _AssigneeChoiceButton extends StatelessWidget {
  const _AssigneeChoiceButton({
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p10,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 80, 5, 5),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.errorStrong, width: 1.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_rounded,
            color: AppColors.errorStrong,
            size: 22,
          ),
          const SizedBox(width: AppSizes.p8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.error.copyWith(
                color: AppColors.errorStrong,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
