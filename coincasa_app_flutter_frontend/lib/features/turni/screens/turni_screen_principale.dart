import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/turni/screens/turno_salvato_con_successo.dart';
import 'package:coincasa_app/features/turni/screens/turno_create_screen.dart';

Future<void> showTurniScreenPrincipaleDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.darkBackground.withValues(alpha: 0.42),
    builder: (_) => const Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p24,
      ),
      child: _TurniPopupPanel(useSafeArea: true),
    ),
  );
}

final _turniCasaProvider =
    FutureProvider.autoDispose.family<Casa?, ActiveCasaController>((
      ref,
      activeCasaController,
    ) async {
  final caseUtente = await ApiProvider.casa.list();
  if (caseUtente.isEmpty) {
    return null;
  }
  return activeCasaController.resolveCasa(caseUtente);
});

final _turniInquiliniProvider =
    FutureProvider.autoDispose.family<List<Inquilino>, String?>((ref, casaId) {
  if (casaId == null || casaId.isEmpty) {
    return const [];
  }
  return ApiProvider.casa.listInquilini(casaId);
});

class TurniScreenPrincipale extends StatelessWidget {
  const TurniScreenPrincipale({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.transparent,
      body: Center(child: _TurniPopupPanel(useSafeArea: true)),
    );
  }
}

class _TurniPopupPanel extends ConsumerStatefulWidget {
  const _TurniPopupPanel({required this.useSafeArea});

  final bool useSafeArea;

  @override
  ConsumerState<_TurniPopupPanel> createState() => _TurniPopupPanelState();
}

class _TurniPopupPanelState extends ConsumerState<_TurniPopupPanel> {
  static const Map<String, int> _frequenze = {
    'Ogni giorno': 1,
    'Ogni 3 giorni': 3,
    'Ogni settimana': 7,
    'Ogni 2 settimane': 14,
    'Ogni mese': 30,
  };

  final _formKey = GlobalKey<FormState>();
  final _taskController = TextEditingController();
  final _dayController = TextEditingController();
  final _monthController = TextEditingController();
  String _frequenza = 'Ogni settimana';
  String? _selectedInquilinoId;
  DateTime? _selectedTurnoDate;
  bool _rotazioneAutomatica = true;
  bool _frequencyExpanded = false;
  bool _assigneeExpanded = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _taskController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  DateTime? _buildTurnoDate() {
    final day = int.tryParse(_dayController.text.trim());
    final month = int.tryParse(_monthController.text.trim());
    if (day == null || month == null || month < 1 || month > 12) {
      return null;
    }

    final now = DateTime.now();
    var candidate = DateTime(now.year, month, day);
    if (candidate.month != month || candidate.day != day) {
      return null;
    }
    if (candidate.isBefore(DateTime(now.year, now.month, now.day))) {
      candidate = DateTime(now.year + 1, month, day);
    }
    return candidate;
  }

  Future<void> _pickTurnoDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTurnoDate ?? _buildTurnoDate() ?? firstDate,
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
      _dayController.text = picked.day.toString().padLeft(2, '0');
      _monthController.text = picked.month.toString().padLeft(2, '0');
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final activeCasaController = ActiveCasaScope.read(context);
    final casa = await ref.read(_turniCasaProvider(activeCasaController).future);
    final inquilini = await ref.read(
      _turniInquiliniProvider(casa?.id).future,
    );
    final assegnatarioId =
        _selectedInquilinoId ??
        (inquilini.isNotEmpty ? inquilini.first.id : '');
    final turnoDate = _selectedTurnoDate ?? _buildTurnoDate();

    if (casa == null || casa.id.isEmpty) {
      setState(() => _errorMessage = 'Nessuna casa disponibile.');
      return;
    }
    if (assegnatarioId.isEmpty) {
      setState(() => _errorMessage = 'Seleziona un assegnatario.');
      return;
    }
    if (turnoDate == null) {
      setState(() => _errorMessage = 'Inserisci una data turno valida.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ApiProvider.turni.create(casa.id, {
        'task': _taskController.text.trim(),
        'dataTurno': _payloadDate(turnoDate).toIso8601String(),
        'cadenzaGiorni': _frequenze[_frequenza] ?? 7,
        'assegnatario': assegnatarioId,
        'rotazioneTurno': _rotazioneAutomatica,
      });

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

  DateTime _payloadDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 12);
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.read(context);
    final casaAsync = ref.watch(_turniCasaProvider(activeCasaController));
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(_turniInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (error, stackTrace) =>
          AsyncValue<List<Inquilino>>.error(error, stackTrace),
    );
    final canSubmit =
        _taskController.text.trim().isNotEmpty && _buildTurnoDate() != null;

    final panel = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 382,
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        elevation: AppSizes.p8,
        child: _TurnoFormPanel(
          formKey: _formKey,
          taskController: _taskController,
          dayController: _dayController,
          monthController: _monthController,
          frequenza: _frequenza,
          frequenze: _frequenze.keys.toList(growable: false),
          frequencyExpanded: _frequencyExpanded,
          assigneeExpanded: _assigneeExpanded,
          selectedInquilinoId: _selectedInquilinoId,
          rotazioneAutomatica: _rotazioneAutomatica,
          inquiliniAsync: inquiliniAsync,
          errorMessage: _errorMessage,
          isSubmitting: _isSubmitting,
          canSubmit: canSubmit,
          onSubmit: _submit,
          onTaskChanged: () => setState(() => _errorMessage = null),
          onDateTap: _pickTurnoDate,
          onDateChanged: () {
            setState(() {
              _selectedTurnoDate = _buildTurnoDate();
              _errorMessage = null;
            });
          },
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
              _selectedInquilinoId = id;
              _assigneeExpanded = false;
              _errorMessage = null;
            });
          },
          onRotazioneChanged: (value) {
            setState(() => _rotazioneAutomatica = value);
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );

    return widget.useSafeArea ? SafeArea(child: panel) : panel;
  }
}

class _TurnoFormPanel extends StatelessWidget {
  const _TurnoFormPanel({
    required this.formKey,
    required this.taskController,
    required this.dayController,
    required this.monthController,
    required this.frequenza,
    required this.frequenze,
    required this.frequencyExpanded,
    required this.assigneeExpanded,
    required this.selectedInquilinoId,
    required this.rotazioneAutomatica,
    required this.inquiliniAsync,
    required this.errorMessage,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onSubmit,
    required this.onTaskChanged,
    required this.onDateTap,
    required this.onDateChanged,
    required this.onFrequencyToggle,
    required this.onFrequencyChanged,
    required this.onAssigneeToggle,
    required this.onAssigneeSelected,
    required this.onRotazioneChanged,
    required this.onCancel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController taskController;
  final TextEditingController dayController;
  final TextEditingController monthController;
  final String frequenza;
  final List<String> frequenze;
  final bool frequencyExpanded;
  final bool assigneeExpanded;
  final String? selectedInquilinoId;
  final bool rotazioneAutomatica;
  final AsyncValue<List<Inquilino>> inquiliniAsync;
  final String? errorMessage;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final VoidCallback onTaskChanged;
  final VoidCallback onDateTap;
  final VoidCallback onDateChanged;
  final VoidCallback onFrequencyToggle;
  final ValueChanged<String> onFrequencyChanged;
  final VoidCallback onAssigneeToggle;
  final ValueChanged<String> onAssigneeSelected;
  final ValueChanged<bool> onRotazioneChanged;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _TurniPanelFrame(
      backgroundColor: AppColors.surface,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TurniPopupTabs(),
              const SizedBox(height: AppSizes.p12),
              Text(
                'Nuovo Turno',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.brandPrimary,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: AppSizes.p20),
              _TaskField(
                controller: taskController,
                onChanged: onTaskChanged,
              ),
              const SizedBox(height: AppSizes.p20),
              _DatePreviewRow(
                dayController: dayController,
                monthController: monthController,
                onDateTap: onDateTap,
                onDateChanged: onDateChanged,
              ),
              const SizedBox(height: AppSizes.p20),
              Text(
                'Frequenza',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.brandPrimary,
                  fontSize: 21,
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
              FilledButton(
                onPressed: isSubmitting || !canSubmit ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandSecondary,
                  disabledBackgroundColor: AppColors.textMutedDark,
                  foregroundColor: AppColors.textOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: AppSizes.p24,
                        height: AppSizes.p24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.textOnDark,
                        ),
                      )
                    : Text(
                        'Salva Turno',
                        style: AppTextStyles.buttonCompact.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(height: AppSizes.p8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p28),
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.errorContainerStrong,
                    foregroundColor: AppColors.errorStrong,
                    side: const BorderSide(
                      color: AppColors.errorStrong,
                      width: 2,
                    ),
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
          ),
        ),
      ),
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
        border: Border.all(color: AppColors.brandAccent, width: 2.5),
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
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.turniTabSurface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.primaryBorder, width: 1.2),
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
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? AppColors.textOnDark : AppColors.textMutedDark,
            fontSize: 13,
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
    return Container(width: 2, height: 15, color: AppColors.textMutedDark);
  }
}

class _TaskField extends StatelessWidget {
  const _TaskField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => onChanged(),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Inserisci il nome del task';
        }
        return null;
      },
      style: AppTextStyles.input.copyWith(fontSize: 19),
      decoration: InputDecoration(
        hintText: 'Nome task...',
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: AppColors.textMutedLight,
          fontSize: 19,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p13,
        ),
        border: _fieldBorder(AppColors.inputBorderDark),
        enabledBorder: _fieldBorder(AppColors.inputBorderDark),
        focusedBorder: _fieldBorder(AppColors.brandAccent, width: 1.5),
        errorBorder: _fieldBorder(AppColors.errorStrong),
        focusedErrorBorder: _fieldBorder(AppColors.errorStrong, width: 1.5),
      ),
    );
  }
}

class _DatePreviewRow extends StatelessWidget {
  const _DatePreviewRow({
    required this.dayController,
    required this.monthController,
    required this.onDateTap,
    required this.onDateChanged,
  });

  final TextEditingController dayController;
  final TextEditingController monthController;
  final VoidCallback onDateTap;
  final VoidCallback onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 47),
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
            child: _DateInputChip(
              controller: dayController,
              hintText: 'gg...',
              validator: _validateDay,
              onChanged: onDateChanged,
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          Expanded(
            child: _DateInputChip(
              controller: monthController,
              hintText: 'MM...',
              validator: _validateMonth,
              onChanged: onDateChanged,
            ),
          ),
          const SizedBox(width: AppSizes.p20),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: onDateTap,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.p10),
                child: Text(
                  'Data turno',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textMutedLight,
                    fontSize: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _validateDay(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'gg';
    }
    final day = int.tryParse(trimmed);
    if (day == null || day < 1 || day > 31) {
      return '1-31';
    }
    return null;
  }

  static String? _validateMonth(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'MM';
    }
    final month = int.tryParse(trimmed);
    if (month == null || month < 1 || month > 12) {
      return '1-12';
    }
    return null;
  }
}

class _DateInputChip extends StatelessWidget {
  const _DateInputChip({
    required this.controller,
    required this.hintText,
    required this.validator,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final FormFieldValidator<String> validator;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 2,
      textInputAction: TextInputAction.next,
      validator: validator,
      onChanged: (_) => onChanged(),
      style: AppTextStyles.inputHint.copyWith(
        color: AppColors.textOnDark,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: AppColors.textOnDark,
          fontSize: 16,
        ),
        filled: true,
        fillColor: AppColors.brandPrimary,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p8,
          vertical: AppSizes.p6,
        ),
        border: _dateInputBorder(AppColors.textOnDark),
        enabledBorder: _dateInputBorder(AppColors.textOnDark),
        focusedBorder: _dateInputBorder(AppColors.brandAccent, width: 1.5),
        errorBorder: _dateInputBorder(AppColors.errorStrong),
        focusedErrorBorder: _dateInputBorder(AppColors.errorStrong, width: 1.5),
        errorStyle: AppTextStyles.fieldError.copyWith(
          color: AppColors.errorStrong,
          height: 0.8,
        ),
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
              border: Border.all(color: AppColors.inputBorderDark, width: 1),
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
        height: 48,
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
                  fontSize: 20,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.brandAccent,
              size: 28,
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
        height: 45,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.dividerOnDark, width: 1),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(
            color: selected
                ? AppColors.turniDropdownSelectedText
                : AppColors.textMutedLight,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _AssigneeDropdown extends StatelessWidget {
  const _AssigneeDropdown({
    required this.inquiliniAsync,
    required this.selectedId,
    required this.expanded,
    required this.rotazioneAutomatica,
    required this.onToggle,
    required this.onSelected,
    required this.onRotazioneChanged,
  });

  final AsyncValue<List<Inquilino>> inquiliniAsync;
  final String? selectedId;
  final bool expanded;
  final bool rotazioneAutomatica;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelected;
  final ValueChanged<bool> onRotazioneChanged;

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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.p10),
          inquiliniAsync.when(
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
              final choices = _assigneeChoices(inquilini);
              final me = choices.first;
              final selected = _selectedInquilino(choices, selectedId);
              final options = _menuOptions(choices, selected);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AssignMeButton(
                        selected: selected.id == me.id,
                        onTap: () => onSelected(me.id),
                      ),
                      const SizedBox(height: AppSizes.p18),
                      _SelectedAssigneeButton(
                        label: 'Assegna a ${_displayName(selected)}',
                        expanded: expanded,
                        onTap: onToggle,
                      ),
                    ],
                  ),
                  if (expanded)
                    Positioned(
                      right: AppSizes.p0,
                      top: AppSizes.p100,
                      child: _AssigneeMenu(
                        options: options,
                        selectedId: selected.id,
                        onSelected: onSelected,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.p14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  'Rotazione automatica',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textMutedLight,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textMutedLight,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p10),
              Switch(
                value: rotazioneAutomatica,
                onChanged: onRotazioneChanged,
                activeThumbColor: AppColors.textOnDark,
                activeTrackColor: AppColors.brandSecondary,
                inactiveThumbColor: AppColors.textMutedLight,
                inactiveTrackColor: AppColors.dividerDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<Inquilino> _assigneeChoices(List<Inquilino> inquilini) {
    final valid = inquilini
        .where((inquilino) => inquilino.id.isNotEmpty)
        .toList(growable: false);
    if (valid.length >= 2) {
      return valid;
    }

    final me = valid.isNotEmpty
        ? valid.first
        : const Inquilino(id: 'preview-me', nome: 'Io', email: '');

    return [
      me,
      const Inquilino(id: 'preview-emma', nome: 'Emma', email: ''),
      const Inquilino(id: 'preview-emilia', nome: 'Emilia', email: ''),
      const Inquilino(id: 'preview-marco', nome: 'Marco', email: ''),
      const Inquilino(id: 'preview-luigi', nome: 'Luigi', email: ''),
    ];
  }

  static List<Inquilino> _menuOptions(
    List<Inquilino> choices,
    Inquilino selected,
  ) {
    return choices
        .where((inquilino) => inquilino.id != selected.id)
        .toList(growable: false);
  }

  static Inquilino _selectedInquilino(
    List<Inquilino> inquilini,
    String? selectedId,
  ) {
    if (selectedId != null) {
      for (final inquilino in inquilini) {
        if (inquilino.id == selectedId) {
          return inquilino;
        }
      }
    }
    return inquilini.first;
  }

  static String _displayName(Inquilino inquilino) {
    final nome = inquilino.nome.trim();
    if (nome.isNotEmpty) {
      return nome.split(RegExp(r'\s+')).first;
    }
    final email = inquilino.email.trim();
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'coinquilino';
  }
}

class _AssignMeButton extends StatelessWidget {
  const _AssignMeButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Container(
        height: 43,
        decoration: BoxDecoration(
          color: AppColors.turniAssignMeSurface,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: selected
              ? Border.all(color: AppColors.statusPositive, width: 2)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p18),
        child: Row(
          children: [
            const Icon(
              Icons.front_hand_outlined,
              color: AppColors.textOnDark,
              size: 23,
            ),
            Expanded(
              child: Text(
                'Assegna a me',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.statusPositive,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p23),
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
        height: 43,
        decoration: BoxDecoration(
          color: AppColors.turniAssigneeSurface,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(color: AppColors.turniAssigneeBorder, width: 1.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p18),
        child: Row(
          children: [
            const Icon(
              Icons.back_hand_outlined,
              color: AppColors.textOnDark,
              size: 23,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.warning,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.warning,
              size: 25,
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
        width: 126,
        decoration: BoxDecoration(
          color: AppColors.turniAssigneeMenuSurface,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(color: AppColors.turniAssigneeBorder, width: 1.2),
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
                  label: _AssigneeDropdown._displayName(inquilino),
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
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.turniAssigneeSelectedSurface
              : AppColors.transparent,
          border: const Border(
            top: BorderSide(color: AppColors.turniAssigneeDivider, width: 1),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.warning,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizes.radius8),
    borderSide: BorderSide(color: color, width: width),
  );
}

OutlineInputBorder _dateInputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizes.radius8),
    borderSide: BorderSide(color: color, width: width),
  );
}
