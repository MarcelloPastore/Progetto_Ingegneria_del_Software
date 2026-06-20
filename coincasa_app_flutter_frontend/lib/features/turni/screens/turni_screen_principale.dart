import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/features/turni/screens/turno_salvato_con_successo.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/domain/viewmodel/turni_viewmodel.dart';

Future<void> showTurniScreenPrincipaleDialog(BuildContext context) {
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
            horizontal: AppSizes.p24,
            vertical: AppSizes.p12,
          ),
          child: TurniPopupPanel(useSafeArea: true),
        ),
      ),
    ),
  );
}

class TurniScreenPrincipale extends StatelessWidget {
  const TurniScreenPrincipale({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.transparent,
      body: Center(child: TurniPopupPanel(useSafeArea: true)),
    );
  }
}

class TurniPopupPanel extends ConsumerStatefulWidget {
  const TurniPopupPanel({
    super.key,
    required this.useSafeArea,
    this.showTabs = true,
    this.showFrame = true,
  });

  final bool useSafeArea;
  final bool showTabs;
  final bool showFrame;

  @override
  ConsumerState<TurniPopupPanel> createState() => _TurniPopupPanelState();
}

class _TurniPopupPanelState extends ConsumerState<TurniPopupPanel> {
  static const Map<String, int> _frequenze = {
    'Ogni giorno': 1,
    'Ogni 3 giorni': 3,
    'Ogni settimana': 7,
    'Ogni 2 settimane': 14,
    'Ogni mese': 30,
  };

  final _formKey = GlobalKey<FormState>();
  final _taskController = TextEditingController();
  String _frequenza = 'Ogni settimana';
  String? selectedInquilinoId;
  late DateTime _selectedTurnoDate;
  bool _rotazioneAutomatica = true;
  bool _frequencyExpanded = false;
  bool _assigneeExpanded = false;
  bool _isSubmitting = false;
  bool _assigneeAutoSelected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTurnoDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _pickTurnoDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTurnoDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 3, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.brandPrimary,
              onPrimary: AppColors.textOnDark,
              secondary: AppColors.brandSecondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTurnoDate = picked;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final activeCasaController = ActiveCasaScope.of(context);
    final casa = await ref.read(
      listaTurniCasaProvider(activeCasaController.selectedCasaId).future,
    );
    final assegnatarioId = selectedInquilinoId?.trim();
    final turnoDate = _selectedTurnoDate;

    if (casa == null || casa.id.isEmpty) {
      setState(() => _errorMessage = 'Nessuna casa disponibile.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(turniViewModelProvider(casa.id).notifier)
          .createTurnoFromFields(
            task: _taskController.text,
            data: turnoDate,
            cadenzaGiorni: _frequenze[_frequenza] ?? 7,
            assegnatarioId: assegnatarioId,
            rotazioneAutomatica: _rotazioneAutomatica,
          );

      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed(TurnoSalvatoConSuccessoScreen.routeName);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Impossibile salvare il turno. Riprova.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.of(context);
    final currentUserIdentity = ref.watch(authViewModelProvider).valueOrNull;
    final casaAsync = ref.watch(
      listaTurniCasaProvider(activeCasaController.selectedCasaId),
    );
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(turniInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (error, stackTrace) =>
          AsyncValue<List<Inquilino>>.error(error, stackTrace),
    );
    if (!_assigneeAutoSelected && inquiliniAsync.hasValue) {
      final assignees = validAssignees(inquiliniAsync.value!);
      final me = currentInquilino(assignees, currentUserIdentity);
      if (me != null) {
        _assigneeAutoSelected = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => selectedInquilinoId = me.id);
        });
      }
    }

    final canSubmit = _taskController.text.trim().isNotEmpty;
    final currentUserId = inquiliniAsync.hasValue
        ? currentInquilino(
            validAssignees(inquiliniAsync.value!),
            currentUserIdentity,
          )?.id
        : null;

    final body = _TurnoFormPanel(
      formKey: _formKey,
      taskController: _taskController,
      selectedTurnoDate: _selectedTurnoDate,

      frequenza: _frequenza,
      frequenze: _frequenze.keys.toList(growable: false),
      frequencyExpanded: _frequencyExpanded,
      assigneeExpanded: _assigneeExpanded,
      selectedInquilinoId: selectedInquilinoId,
      rotazioneAutomatica: _rotazioneAutomatica,
      currentUserId: currentUserId,
      inquiliniAsync: inquiliniAsync,
      errorMessage: _errorMessage,
      isSubmitting: _isSubmitting,
      canSubmit: canSubmit,
      onSubmit: _submit,
      onTaskChanged: () => setState(() => _errorMessage = null),
      onDateTap: _pickTurnoDate,
      onFrequencyToggle: () {
        setState(() {
          _frequencyExpanded = !_frequencyExpanded;
          _assigneeExpanded = false;
        });
      },
      onFrequencyChanged: (value) {
        setState(() {
          _frequenza = value;
          _frequencyExpanded = false;
        });
      },
      onAssigneeToggle: () {
        setState(() {
          _assigneeExpanded = !_assigneeExpanded;
          _frequencyExpanded = false;
        });
      },
      onAssigneeSelected: (id) {
        setState(() {
          if (selectedInquilinoId == id) {
            selectedInquilinoId = null;
          } else {
            selectedInquilinoId = id;
          }
          _assigneeExpanded = false;
          _errorMessage = null;
        });
      },
      onRotazioneChanged: (value) {
        setState(() => _rotazioneAutomatica = value);
      },
      onCancel: () => Navigator.of(context).pop(),
      showTabs: widget.showTabs,
      showFrame: widget.showFrame,
    );

    final panel = widget.showFrame
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppSizes.p382,
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              elevation: AppSizes.p8,
              child: body,
            ),
          )
        : body;

    return widget.useSafeArea ? SafeArea(child: panel) : panel;
  }
}

class _TurnoFormPanel extends StatelessWidget {
  const _TurnoFormPanel({
    required this.formKey,
    required this.taskController,
    required this.selectedTurnoDate,
    required this.frequenza,
    required this.frequenze,
    required this.frequencyExpanded,
    required this.assigneeExpanded,
    required this.selectedInquilinoId,
    required this.rotazioneAutomatica,
    required this.currentUserId,
    required this.inquiliniAsync,
    required this.errorMessage,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onSubmit,
    required this.onTaskChanged,
    required this.onDateTap,
    required this.onFrequencyToggle,
    required this.onFrequencyChanged,
    required this.onAssigneeToggle,
    required this.onAssigneeSelected,
    required this.onRotazioneChanged,
    required this.onCancel,
    required this.showTabs,
    required this.showFrame,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController taskController;
  final DateTime selectedTurnoDate;
  final String frequenza;
  final List<String> frequenze;
  final bool frequencyExpanded;
  final bool assigneeExpanded;
  final String? selectedInquilinoId;
  final bool rotazioneAutomatica;
  final String? currentUserId;
  final AsyncValue<List<Inquilino>> inquiliniAsync;
  final String? errorMessage;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final VoidCallback onTaskChanged;
  final VoidCallback onDateTap;
  final VoidCallback onFrequencyToggle;
  final ValueChanged<String> onFrequencyChanged;
  final VoidCallback onAssigneeToggle;
  final ValueChanged<String> onAssigneeSelected;
  final ValueChanged<bool> onRotazioneChanged;
  final VoidCallback onCancel;
  final bool showTabs;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTabs) ...[
              const _TurniPopupTabs(),
              const SizedBox(height: AppSizes.p12),
            ],
            Text(
              'Nuovo Turno',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.brandPrimary,
                fontSize: AppSizes.p23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.p14),
            AppTaskField(
              controller: taskController,
              hasError: false,
              onChanged: (_) => onTaskChanged(),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Inserisci il nome del task'
                  : null,
            ),
            const SizedBox(height: AppSizes.p14),
            _DatePreviewRow(
              selectedDate: selectedTurnoDate,
              onDateTap: onDateTap,
            ),
            const SizedBox(height: AppSizes.p14),
            Text(
              'FREQUENZA',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.brandPrimaryDark,
                fontSize: AppSizes.p13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            _FrequencyDropdown(
              value: frequenza,
              values: frequenze,
              expanded: frequencyExpanded,
              onToggle: onFrequencyToggle,
              onChanged: onFrequencyChanged,
            ),
            const SizedBox(height: AppSizes.p24),
            _AssigneeDropdown(
              inquiliniAsync: inquiliniAsync,
              selectedId: selectedInquilinoId,
              currentUserId: currentUserId,
              canAssignOthers: ActiveCasaScope.of(context).isHomeAdmin,
              expanded: assigneeExpanded,
              rotazioneAutomatica: rotazioneAutomatica,
              onToggle: onAssigneeToggle,
              onSelected: onAssigneeSelected,
              onRotazioneChanged: onRotazioneChanged,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSizes.p10),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.error.copyWith(
                  color: AppColors.errorStrong,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.p22),
            FabSaveButton(
              label: 'Salva turno',
              onPressed: isSubmitting || !canSubmit ? null : onSubmit,
              isLoading: isSubmitting,
            ),
            const SizedBox(height: AppSizes.p8),
            AppCancelButton(onPressed: isSubmitting ? null : onCancel),
          ],
        ),
      ),
    );

    if (!showFrame) {
      return form;
    }

    return _TurniPanelFrame(
      backgroundColor: AppColors.errorStrong,
      child: form,
    );
  }
}

class _TurniPanelFrame extends StatelessWidget {
  const _TurniPanelFrame({required this.child, required this.backgroundColor});

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(color: AppColors.brandAccent, width: AppSizes.p2_5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: AppSizes.p8,
            offset: Offset(0, AppSizes.p5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p0,
        AppSizes.p16,
        AppSizes.p10,
      ),
      child: child,
    );
  }
}

class _TurniPopupTabs extends StatelessWidget {
  const _TurniPopupTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.p42,
      decoration: BoxDecoration(
        color: AppColors.turniTabSurface,
        borderRadius: BorderRadius.circular(AppSizes.radius17),
        border: Border.all(
          color: AppColors.primaryBorder,
          width: AppSizes.p1_2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: AppSizes.p5,
            offset: Offset(0, AppSizes.p3),
          ),
        ],
      ),
      child: Row(
        children: const [
          _PopupTab(label: 'Spesa'),
          _PopupDivider(),
          _PopupTab(label: 'Problema'),
          _PopupTab(label: 'Turno', selected: true),
          _PopupTab(label: 'Scadenza'),
        ],
      ),
    );
  }
}

class _PopupTab extends StatelessWidget {
  const _PopupTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: double.infinity,
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                color: AppColors.brandAccent,
                borderRadius: BorderRadius.circular(AppSizes.radius14),
              )
            : null,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? AppColors.textOnDark : AppColors.textMutedDark,
            fontSize: AppSizes.p13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PopupDivider extends StatelessWidget {
  const _PopupDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.p2,
      height: AppSizes.p15,
      color: AppColors.textMutedDark,
    );
  }
}

class _DatePreviewRow extends StatelessWidget {
  const _DatePreviewRow({required this.selectedDate, required this.onDateTap});

  final DateTime selectedDate;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final label = 'Data inizio turno: $day/$month';

    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.p47),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: AppSizes.p6,
            offset: Offset(0, AppSizes.p4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p14),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onDateTap,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.p10),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.brandAccent,
                      size: AppSizes.p20,
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: AppSizes.p19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyDropdown extends StatelessWidget {
  const _FrequencyDropdown({
    required this.value,
    required this.values,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DropdownHeader(label: value, expanded: expanded, onTap: onToggle),
        if (expanded)
          Container(
            decoration: BoxDecoration(
              color: AppColors.dividerDark,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSizes.radius8),
              ),
              border: Border.all(
                color: AppColors.inputBorderDark,
                width: AppSizes.p1,
              ),
            ),
            child: Column(
              children: values
                  .map(
                    (option) => _DropdownOption(
                      label: option,
                      selected: option == value,
                      onTap: () => onChanged(option),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _DropdownHeader extends StatelessWidget {
  const _DropdownHeader({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Container(
        height: AppSizes.p48,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.input.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: AppSizes.p20,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.brandAccent,
              size: AppSizes.p28,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownOption extends StatelessWidget {
  const _DropdownOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppSizes.p45,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.dividerOnDark,
              width: AppSizes.p1,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(
            color: selected
                ? AppColors.turniDropdownSelectedText
                : AppColors.textMutedLight,
            fontSize: AppSizes.p16,
          ),
        ),
      ),
    );
  }
}

class _AssigneeDropdown extends StatefulWidget {
  const _AssigneeDropdown({
    required this.inquiliniAsync,
    required this.selectedId,
    required this.currentUserId,
    required this.canAssignOthers,
    required this.expanded,
    required this.rotazioneAutomatica,
    required this.onToggle,
    required this.onSelected,
    required this.onRotazioneChanged,
  });

  final AsyncValue<List<Inquilino>> inquiliniAsync;
  final String? selectedId;
  final String? currentUserId;
  final bool canAssignOthers;
  final bool expanded;
  final bool rotazioneAutomatica;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelected;
  final ValueChanged<bool> onRotazioneChanged;

  @override
  State<_AssigneeDropdown> createState() => _AssigneeDropdownState();
}

class _AssigneeDropdownState extends State<_AssigneeDropdown> {
  final LayerLink _menuLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _overlayInsertScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.expanded) {
      _scheduleShowOverlay();
    }
  }

  @override
  void didUpdateWidget(covariant _AssigneeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && _overlayEntry == null) {
      _scheduleShowOverlay();
    } else if (!widget.expanded && _overlayEntry != null) {
      _hideOverlay();
    } else if (widget.expanded && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.expanded) {
          _overlayEntry?.markNeedsBuild();
        }
      });
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _scheduleShowOverlay() {
    if (_overlayEntry != null || _overlayInsertScheduled) {
      return;
    }

    _overlayInsertScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayInsertScheduled = false;
      if (mounted && widget.expanded) {
        _showOverlay();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null || !mounted) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final assignees = validAssignees(
          widget.inquiliniAsync.value ?? const [],
        );
        final options = assigneesExceptId(assignees, widget.currentUserId);
        final selected = selectedInquilino(options, widget.selectedId);

        if (selected == null || options.isEmpty) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggle,
                child: Container(
                  color: AppColors.darkBackground.withValues(alpha: 0.28),
                ),
              ),
            ),
            CompositedTransformFollower(
              link: _menuLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, AppSizes.p8),
              child: _AssigneeMenu(
                options: options,
                selectedId: selected.id,
                onSelected: widget.onSelected,
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowStrong,
            blurRadius: AppSizes.p6,
            offset: Offset(0, AppSizes.p4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p12,
        AppSizes.p12,
        AppSizes.p12,
        AppSizes.p10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assegnatario',
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textMutedLight,
              fontSize: AppSizes.p16,
            ),
          ),
          const SizedBox(height: AppSizes.p10),
          widget.inquiliniAsync.when(
            loading: () => const SizedBox(
              height: AppSizes.p68,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandAccent,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            error: (error, stackTrace) => Text(
              'Impossibile caricare gli assegnatari.',
              style: AppTextStyles.error.copyWith(color: AppColors.errorStrong),
            ),
            data: (inquilini) {
              final assignees = validAssignees(inquilini);
              final otherHousemates = assigneesExceptId(
                assignees,
                widget.currentUserId,
              );
              final selected = selectedInquilino(
                otherHousemates,
                widget.selectedId,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.canAssignOthers) ...[
                    _AssignMeButton(
                      selected:
                          widget.currentUserId != null &&
                          widget.selectedId == widget.currentUserId,
                      onTap: widget.currentUserId == null
                          ? null
                          : () => widget.onSelected(widget.currentUserId!),
                    ),
                  ] else ...[
                    _AssignMeButton(
                      selected:
                          widget.currentUserId != null &&
                          widget.selectedId == widget.currentUserId,
                      onTap: widget.currentUserId == null
                          ? null
                          : () => widget.onSelected(widget.currentUserId!),
                    ),
                    if (selected != null && otherHousemates.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.p18),
                      CompositedTransformTarget(
                        link: _menuLink,
                        child: _SelectedAssigneeButton(
                          label: 'Assegna a ${assigneeDisplayName(selected)}',
                          expanded: widget.expanded,
                          onTap: widget.onToggle,
                        ),
                      ),
                    ],
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.p14),
          Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rotazione automatica',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: widget.canAssignOthers
                            ? AppColors.textMutedLight
                            : AppColors.textMutedDark,
                        decoration: widget.canAssignOthers
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: widget.canAssignOthers
                            ? AppColors.textMutedLight
                            : AppColors.textMutedDark,
                      ),
                    ),
                    if (!widget.canAssignOthers) ...[
                      const SizedBox(height: AppSizes.p3),
                      const Row(
                        children: [
                          Text(
                            '( solo HomeAdmin )',
                            style: TextStyle(
                              color: AppColors.warningDark,
                              fontSize: AppSizes.p12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: AppSizes.p4),
                          Icon(
                            Icons.warning,
                            color: AppColors.warningDark,
                            size: AppSizes.p13,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p10),
              AppSwitch(
                value: widget.rotazioneAutomatica,
                onChanged: widget.canAssignOthers
                    ? widget.onRotazioneChanged
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignMeButton extends StatelessWidget {
  const _AssignMeButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: selected ? 48 : 43,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.statusPositive.withValues(alpha: 0.15)
              : AppColors.turniAssignMeSurface,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: selected ? AppColors.statusPositive : AppColors.transparent,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.statusPositive.withValues(alpha: 0.35),
                    blurRadius: AppSizes.p12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p18),
        child: Row(
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: const Image(
                image: AssetImage('assets/Icons/assegna_a_me_mano.png'),
                width: AppSizes.p22,
                height: AppSizes.p22,
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.statusPositive,
                  fontSize: selected ? 17 : 16,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                ),
                child: const Text('Assegna a me'),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: selected ? 1.0 : 0.0,
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.statusPositive,
                size: AppSizes.p20,
              ),
            ),
            if (!selected) const SizedBox(width: AppSizes.p20),
          ],
        ),
      ),
    );
  }
}

class _SelectedAssigneeButton extends StatelessWidget {
  const _SelectedAssigneeButton({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Container(
        height: AppSizes.p43,
        decoration: BoxDecoration(
          color: AppColors.turniAssigneeSurface,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: AppColors.turniAssigneeBorder,
            width: AppSizes.p1_2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p18),
        child: Row(
          children: [
            const Image(
              image: AssetImage('assets/Icons/assegna_a_qualcuno_help.png'),
              width: AppSizes.p22,
              height: AppSizes.p22,
              fit: BoxFit.contain,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.warning,
                  fontSize: AppSizes.p16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.warning,
              size: AppSizes.p25,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneeMenu extends StatelessWidget {
  const _AssigneeMenu({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Inquilino> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        width: AppSizes.p126,
        decoration: BoxDecoration(
          color: AppColors.turniAssigneeMenuSurface,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: AppColors.turniAssigneeBorder,
            width: AppSizes.p1_2,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p6,
              offset: Offset(0, AppSizes.p4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (inquilino) => _AssigneeOption(
                  label: assigneeDisplayName(inquilino),
                  selected: inquilino.id == selectedId,
                  onTap: () => onSelected(inquilino.id),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _AssigneeOption extends StatelessWidget {
  const _AssigneeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: AppSizes.p54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.turniAssigneeSelectedSurface
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: const Border(),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.warning,
            fontSize: AppSizes.p20,
          ),
        ),
      ),
    );
  }
}
