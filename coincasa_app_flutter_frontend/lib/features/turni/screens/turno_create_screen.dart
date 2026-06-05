import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/turni/screens/turno_salvato_con_successo.dart';

final turniCreateCasaProvider = FutureProvider.autoDispose
    .family<Casa?, String?>((ref, selectedCasaId) async {
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

final turniCreateInquiliniProvider = FutureProvider.autoDispose
    .family<List<Inquilino>, String?>((ref, casaId) {
      if (casaId == null || casaId.isEmpty) {
        return const [];
      }
      return ApiProvider.casa.listInquilini(casaId);
    });

final turnoCreateFormProvider =
    StateNotifierProvider.autoDispose<
      _TurnoCreateFormController,
      _TurnoCreateFormState
    >((ref) => _TurnoCreateFormController());

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

class TurnoCreateScreen extends ConsumerStatefulWidget {
  const TurnoCreateScreen({super.key});

  static const routeName = '/turni/nuovo';

  @override
  ConsumerState<TurnoCreateScreen> createState() => _TurnoCreateScreenState();
}

class _TurnoCreateScreenState extends ConsumerState<TurnoCreateScreen> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final controller = ref.read(turnoCreateFormProvider.notifier);
    final form = ref.read(turnoCreateFormProvider);
    final activeCasaController = ActiveCasaScope.of(context);
    final casa = await ref.read(
      turniCreateCasaProvider(activeCasaController.selectedCasaId).future,
    );
    final assigneeId = form.selectedInquilinoId?.trim();
    final turnoDate = form.turnoDate;

    if (!controller.validateBeforeSubmit()) {
      return;
    }
    if (casa == null || casa.id.isEmpty) {
      controller.setSubmitError('Nessuna casa disponibile.');
      return;
    }
    if (turnoDate == null) {
      controller.setSubmitError('Dati mancanti: compila i campi necessari');
      return;
    }

    controller.setSubmitting(true);
    try {
      await ApiProvider.turni.create(casa.id, {
        'task': form.task.trim(),
        'dataTurno': _payloadDate(turnoDate).toIso8601String(),
        'cadenzaGiorni':
            _TurnoCreateFormState.frequencyDays[form.frequency] ?? 7,
        if (assigneeId != null && assigneeId.isNotEmpty)
          'assegnatario': assigneeId,
        'rotazioneTurno': form.autoRotation,
      });

      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushReplacementNamed(TurnoSalvatoConSuccessoScreen.routeName);
    } catch (_) {
      controller.setSubmitError('Impossibile salvare il turno. Riprova.');
    }
  }

  DateTime _payloadDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 12);
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.of(context);
    final form = ref.watch(turnoCreateFormProvider);
    final controller = ref.read(turnoCreateFormProvider.notifier);
    final casaAsync = ref.watch(
      turniCreateCasaProvider(activeCasaController.selectedCasaId),
    );
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(turniCreateInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (error, stackTrace) =>
          AsyncValue<List<Inquilino>>.error(error, stackTrace),
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/turni'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(9, 8, 9, 13),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  101,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Inserisci turno',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 17),
                _TaskField(
                  controller: _taskController,
                  hasError: form.showErrors && form.task.trim().isEmpty,
                  onChanged: controller.setTask,
                ),
                const SizedBox(height: 25),
                inquiliniAsync.when(
                  loading: () => const _AssigneeLoading(),
                  error: (_, _) => _AssigneeSection(
                    inquilini: const [],
                    canAssignOthers: false,
                    currentUserId: null,
                    selectedId: form.selectedInquilinoId,
                    showError:
                        form.showErrors && form.selectedInquilinoId == null,
                    onSelected: controller.setAssignee,
                  ),
                  data: (inquilini) {
                    final assignees = _assigneeChoices(inquilini);
                    final currentUser = _resolveCurrentInquilino(assignees);
                    return _AssigneeSection(
                      inquilini: assignees,
                      canAssignOthers: currentUser?.isHomeAdmin == true,
                      currentUserId: currentUser?.id,
                      selectedId: form.selectedInquilinoId,
                      showError:
                          form.showErrors && form.selectedInquilinoId == null,
                      onSelected: controller.setAssignee,
                    );
                  },
                ),
                const SizedBox(height: 20),
                _DateRow(
                  selectedDate: form.turnoDate,
                  hasError: form.showErrors && !form.hasValidDate,
                  onPickDate: () => _pickDate(form.turnoDate),
                ),
                if (form.showDatePastError) ...[
                  const SizedBox(height: 12),
                  const _ErrorLine(
                    message: 'Data errata: seleziona una data futura',
                  ),
                ],
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    'Frequenza',
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.textMutedLight,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FrequencyDropdown(
                    value: form.frequency,
                    expanded: form.frequencyExpanded,
                    hasError: form.showErrors && form.frequency.isEmpty,
                    onToggle: controller.toggleFrequency,
                    onChanged: controller.setFrequency,
                  ),
                ),
                SizedBox(height: form.frequencyExpanded ? 16 : 34),
                // determine if current user is HomeAdmin to enable rotation toggle
                Builder(builder: (context) {
                  final assignees = inquiliniAsync.value ?? const <Inquilino>[];
                  final currentUser = _resolveCurrentInquilino(assignees);
                  final canToggleRotation = currentUser?.isHomeAdmin == true;
                  return _AutoRotationRow(
                    value: form.autoRotation,
                    onChanged: canToggleRotation ? controller.setAutoRotation : (_) {},
                    enabled: canToggleRotation,
                  );
                }),
                if (form.showMissingError) ...[
                  const SizedBox(height: 18),
                  const _ErrorLine(
                    message: 'Dati mancanti: compila i campi necessari',
                  ),
                ],
                SizedBox(height: form.showMissingError ? 20 : 34),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SaveButton(
                    enabled: form.canSubmit,
                    submitting: form.isSubmitting,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 47),
                  child: _CancelButton(
                    enabled: !form.isSubmitting,
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

  Future<void> _pickDate(DateTime? selectedDate) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 3, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.brandPrimary,
              onPrimary: AppColors.textOnDark,
              secondary: AppColors.brandAccent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    ref.read(turnoCreateFormProvider.notifier).setPickedDate(picked);
  }

  static List<Inquilino> _assigneeChoices(List<Inquilino> inquilini) {
    final valid = inquilini.where((item) => item.id.isNotEmpty).toList();
    if (valid.isNotEmpty) {
      return valid;
    }
    return const [
      Inquilino(
        id: 'preview-fp',
        nome: 'Francesco',
        cognome: 'Piras',
        email: '',
      ),
      Inquilino(id: 'preview-mr', nome: 'Mario', cognome: 'Rossi', email: ''),
      Inquilino(id: 'preview-al', nome: 'Anna', cognome: 'Lombardi', email: ''),
      Inquilino(id: 'preview-gl', nome: 'Giulia', cognome: 'Lodi', email: ''),
    ];
  }
}

class _TurnoCreateFormState {
  const _TurnoCreateFormState({
    this.task = '',
    this.day = '',
    this.month = '',
    this.frequency = 'Ogni settimana',
    this.selectedInquilinoId,
    this.autoRotation = true,
    this.frequencyExpanded = false,
    this.showErrors = false,
    this.isSubmitting = false,
    this.submitError,
  });

  static const frequencies = [
    'Ogni giorno',
    'Ogni 3 giorni',
    'Ogni settimana',
    'Ogni 2 settimane',
    'Ogni mese',
  ];

  static const frequencyDays = {
    'Ogni giorno': 1,
    'Ogni 3 giorni': 3,
    'Ogni settimana': 7,
    'Ogni 2 settimane': 14,
    'Ogni mese': 30,
  };

  final String task;
  final String day;
  final String month;
  final String frequency;
  final String? selectedInquilinoId;
  final bool autoRotation;
  final bool frequencyExpanded;
  final bool showErrors;
  final bool isSubmitting;
  final String? submitError;

  DateTime? get turnoDate => _parseDate(day, month);
  bool get hasValidDate => turnoDate != null && !isPastDate;
  bool get isPastDate {
    final parsed = _parseDate(day, month, allowPast: true);
    if (parsed == null) {
      return false;
    }
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return parsed.isBefore(todayOnly);
  }

  bool get showDatePastError => showErrors && isPastDate;
  bool get showMissingError =>
      showErrors &&
      submitError == null &&
      (task.trim().isEmpty || !hasValidDate);
  bool get canSubmit =>
      !isSubmitting &&
      task.trim().isNotEmpty &&
      hasValidDate &&
      frequency.isNotEmpty;

  _TurnoCreateFormState copyWith({
    String? task,
    String? day,
    String? month,
    String? frequency,
    Object? selectedInquilinoId = _sentinel,
    bool? autoRotation,
    bool? frequencyExpanded,
    bool? showErrors,
    bool? isSubmitting,
    Object? submitError = _sentinel,
  }) {
    return _TurnoCreateFormState(
      task: task ?? this.task,
      day: day ?? this.day,
      month: month ?? this.month,
      frequency: frequency ?? this.frequency,
      selectedInquilinoId: selectedInquilinoId == _sentinel
          ? this.selectedInquilinoId
          : selectedInquilinoId as String?,
      autoRotation: autoRotation ?? this.autoRotation,
      frequencyExpanded: frequencyExpanded ?? this.frequencyExpanded,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError == _sentinel
          ? this.submitError
          : submitError as String?,
    );
  }

  static DateTime? _parseDate(
    String dayValue,
    String monthValue, {
    bool allowPast = false,
  }) {
    final day = int.tryParse(dayValue.trim());
    final month = _parseMonth(monthValue);
    if (day == null || month == null) {
      return null;
    }

    final now = DateTime.now();
    final parsed = DateTime(now.year, month, day);
    if (parsed.day != day || parsed.month != month) {
      return null;
    }
    if (allowPast || !parsed.isBefore(DateTime(now.year, now.month, now.day))) {
      return parsed;
    }
    return null;
  }

  static int? _parseMonth(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    final numeric = int.tryParse(normalized);
    if (numeric != null && numeric >= 1 && numeric <= 12) {
      return numeric;
    }
    return const {
      'gen': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'mag': 5,
      'giu': 6,
      'lug': 7,
      'ago': 8,
      'set': 9,
      'ott': 10,
      'nov': 11,
      'dic': 12,
    }[normalized];
  }
}

class _TurnoCreateFormController extends StateNotifier<_TurnoCreateFormState> {
  _TurnoCreateFormController() : super(const _TurnoCreateFormState());

  void setTask(String value) =>
      state = state.copyWith(task: value, submitError: null);
  void setDay(String value) =>
      state = state.copyWith(day: value, submitError: null);
  void setMonth(String value) =>
      state = state.copyWith(month: value, submitError: null);
  void setFrequency(String value) => state = state.copyWith(
    frequency: value,
    frequencyExpanded: false,
    submitError: null,
  );
  void setAssignee(String id) =>
      state = state.copyWith(selectedInquilinoId: id, submitError: null);
  void setAutoRotation(bool value) =>
      state = state.copyWith(autoRotation: value);
  void toggleFrequency() =>
      state = state.copyWith(frequencyExpanded: !state.frequencyExpanded);
  void setPickedDate(DateTime date) => state = state.copyWith(
    day: date.day.toString().padLeft(2, '0'),
    month: _monthLabel(date.month),
    submitError: null,
  );
  void setSubmitting(bool value) => state = state.copyWith(isSubmitting: value);
  void setSubmitError(String message) => state = state.copyWith(
    submitError: message,
    showErrors: true,
    isSubmitting: false,
  );

  bool validateBeforeSubmit() {
    state = state.copyWith(showErrors: true, submitError: null);
    return state.task.trim().isNotEmpty && state.hasValidDate;
  }
}

class _TaskField extends StatelessWidget {
  const _TaskField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.input.copyWith(fontSize: 20),
      decoration: InputDecoration(
        hintText: 'Nome task...',
        suffixText: hasError ? '*' : null,
        suffixStyle: AppTextStyles.input.copyWith(
          color: AppColors.errorStrong,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: hasError ? AppColors.errorStrong : AppColors.textMutedLight,
          fontSize: 20,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated.withValues(alpha: 0.86),
        contentPadding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
        enabledBorder: _outline(
          hasError ? AppColors.errorStrong : AppColors.transparent,
        ),
        focusedBorder: _outline(
          hasError ? AppColors.errorStrong : AppColors.brandAccent,
        ),
      ),
    );
  }
}

class _AssigneeLoading extends StatelessWidget {
  const _AssigneeLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 74,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.brandAccent,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}

class _AssigneeSection extends StatelessWidget {
  const _AssigneeSection({
    required this.inquilini,
    required this.canAssignOthers,
    required this.currentUserId,
    required this.selectedId,
    required this.showError,
    required this.onSelected,
  });

  final List<Inquilino> inquilini;
  final bool canAssignOthers;
  final String? currentUserId;
  final String? selectedId;
  final bool showError;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final fallbackId = currentUserId?.trim().isNotEmpty == true
        ? currentUserId!.trim()
        : (inquilini.isNotEmpty ? inquilini.first.id : 'unknown-user-id');

    if (!canAssignOthers || inquilini.length <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _AssignMeButton(
          selected: selectedId == fallbackId,
          onTap: () => onSelected(fallbackId),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Assegna a',
                style: AppTextStyles.input.copyWith(
                  color: showError
                      ? AppColors.errorStrong
                      : AppColors.textOnDark,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              if (showError)
                Text(
                  '*',
                  style: AppTextStyles.input.copyWith(
                    color: AppColors.errorStrong,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: List.generate(inquilini.take(4).length, (index) {
              final inquilino = inquilini[index];
              final label = _initials(inquilino);
              final selected = inquilino.id == selectedId;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _AssigneeChip(
                    label: label,
                    color: _chipColor(index),
                    selected: selected,
                    showError: showError,
                    onTap: () => onSelected(inquilino.id),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  static String _initials(Inquilino inquilino) {
    final source = inquilino.nomeCompleto.trim().isNotEmpty
        ? inquilino.nomeCompleto
        : inquilino.email.split('@').first;
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (source.isEmpty) {
      return '?';
    }
    return source.length >= 2
        ? source.substring(0, 2).toUpperCase()
        : source.toUpperCase();
  }

  static Color _chipColor(int index) {
    final colors = const [
      AppColors.statusSuccess,
      AppColors.turniAssigneeSurface,
      Color(0xFF6E3B7C),
      Color(0xFF347A88),
    ];
    return colors[index % colors.length];
  }
}

class _AssignMeButton extends StatelessWidget {
  const _AssignMeButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AnimatedAssignMeButton(selected: selected, onTap: onTap);
  }
}

class _AnimatedAssignMeButton extends StatefulWidget {
  const _AnimatedAssignMeButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AnimatedAssignMeButton> createState() =>
      _AnimatedAssignMeButtonState();
}

class _AnimatedAssignMeButtonState extends State<_AnimatedAssignMeButton> {
  bool _pressed = false;

  Color _topColor() {
    if (_pressed) {
      return widget.selected
          ? const Color(0xFF7BE47E)
          : const Color(0xFF77C879);
    }
    return widget.selected ? const Color(0xFF53C95B) : const Color(0xFF68B86C);
  }

  Color _bottomColor() {
    if (_pressed) {
      return widget.selected
          ? const Color(0xFF2C7D34)
          : const Color(0xFF256A2D);
    }
    return widget.selected ? const Color(0xFF2E9F3D) : const Color(0xFF2E7736);
  }

  Color _textColor() {
    if (_pressed) {
      return const Color(0xFFF3FFF3);
    }
    return widget.selected ? const Color(0xFFE7FFE8) : AppColors.statusPositive;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (value) {
          if (value != _pressed && mounted) {
            setState(() => _pressed = value);
          }
        },
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_topColor(), _bottomColor()],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            border: Border.all(
              color: widget.selected
                  ? const Color(0xFFB4FFB8)
                  : const Color(0xFF17371A),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: _pressed
                    ? const Color(0x33000000)
                    : const Color(0x55000000),
                blurRadius: _pressed ? 4 : 10,
                offset: Offset(0, _pressed ? 1 : 4),
              ),
            ],
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: _pressed ? 0.985 : 1,
            child: Text(
              'Assegna a me',
              style: AppTextStyles.bodyStrong.copyWith(
                color: _textColor(),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.showError,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool showError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(
            color: showError
                ? AppColors.errorStrong
                : selected
                ? _textColor(label)
                : AppColors.transparent,
            width: 2.2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyStrong.copyWith(
            color: _textColor(label),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  static Color _textColor(String label) {
    return switch (label) {
      'FP' => AppColors.statusPositive,
      'MR' => AppColors.statusWarning,
      'GL' => Colors.cyanAccent,
      _ => AppColors.turniDropdownSelectedText,
    };
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.selectedDate,
    required this.hasError,
    required this.onPickDate,
  });

  final DateTime? selectedDate;
  final bool hasError;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    String label = 'Data Inizio Turno';
    if (selectedDate != null) {
      final day = selectedDate!.day.toString().padLeft(2, '0');
      final month = selectedDate!.month.toString().padLeft(2, '0');
      label = 'Data inizio turno: $day/$month';
    } else if (hasError) {
      label = 'Data Inizio Turno *';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: hasError ? AppColors.errorStrong : AppColors.transparent,
            width: 2.4,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: (hasError || selectedDate != null)
                          ? (selectedDate != null ? AppColors.brandAccent : AppColors.errorStrong)
                          : AppColors.textMutedLight,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: (hasError || selectedDate != null)
                              ? (selectedDate != null ? AppColors.textOnDark : AppColors.errorStrong)
                              : AppColors.textMutedLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _FrequencyDropdown extends StatelessWidget {
  const _FrequencyDropdown({
    required this.value,
    required this.expanded,
    required this.hasError,
    required this.onToggle,
    required this.onChanged,
  });

  final String value;
  final bool expanded;
  final bool hasError;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: Container(
            height: 49,
            decoration: BoxDecoration(
              color: expanded
                  ? AppColors.brandPrimary
                  : AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(AppSizes.radius8),
                bottom: Radius.circular(expanded ? 0 : AppSizes.radius8),
              ),
              border: hasError
                  ? Border.all(color: AppColors.errorStrong, width: 2.4)
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowStrong,
                  blurRadius: AppSizes.p5,
                  offset: Offset(0, AppSizes.p3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasError ? '$value      *' : value,
                    style: AppTextStyles.input.copyWith(
                      color: hasError
                          ? AppColors.errorStrong
                          : AppColors.textMutedLight,
                      fontSize: 20,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: hasError
                      ? AppColors.errorStrong
                      : AppColors.brandAccent,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Container(
            decoration: BoxDecoration(
              color: AppColors.dividerDark,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSizes.radius8),
              ),
              border: Border.all(color: AppColors.inputBorderDark),
            ),
            child: Column(
              children: _TurnoCreateFormState.frequencies.map((option) {
                return InkWell(
                  onTap: () => onChanged(option),
                  child: Container(
                    height: 45,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.dividerOnDark),
                      ),
                    ),
                    child: Text(
                      option,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: option == value
                            ? AppColors.turniDropdownSelectedText
                            : AppColors.textMutedLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _AutoRotationRow extends StatelessWidget {
  const _AutoRotationRow({required this.value, required this.onChanged, this.enabled = true});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
              'Rotazione automatica assegnatario',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: AppTextStyles.bodyStrong.copyWith(
                color: enabled ? AppColors.textMutedLight : AppColors.textMutedDark,
                fontSize: 16,
              ),
            ),
        ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: enabled ? AppColors.textOnDark : AppColors.textMutedDark,
            activeTrackColor: enabled ? AppColors.brandAccent : AppColors.dividerDark,
            inactiveThumbColor: AppColors.textOnDark,
            inactiveTrackColor: AppColors.textMutedDark,
          ),
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 24),
        const Icon(Icons.error, color: AppColors.errorStrong, size: 21),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.error.copyWith(
              color: AppColors.errorStrong,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.submitting,
    required this.onPressed,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        disabledBackgroundColor: AppColors.textMutedDark,
        foregroundColor: AppColors.textOnDark,
        disabledForegroundColor: AppColors.textOnDark,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: submitting
          ? const SizedBox(
              width: 23,
              height: 23,
              child: CircularProgressIndicator(
                color: AppColors.textOnDark,
                strokeWidth: 2.4,
              ),
            )
          : Text(
              'Salva Turno',
              style: AppTextStyles.buttonCompact.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.errorStrong.withValues(alpha: 0.25),
        foregroundColor: AppColors.errorStrong,
        side: const BorderSide(color: AppColors.errorStrong, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
      ),
      child: Text(
        'Annulla',
        style: AppTextStyles.buttonCompact.copyWith(
          color: AppColors.errorStrong,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

const Object _sentinel = Object();

String _monthLabel(int month) {
  return const [
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic',
  ][month - 1];
}

OutlineInputBorder _outline(Color color, {double width = 1.3}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizes.radius8),
    borderSide: BorderSide(color: color, width: width),
  );
}
