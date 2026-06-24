import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/ui/turni/screens/turno_salvato_successo.dart';
import 'package:coincasa_app/domain/viewmodel/turni_viewmodel.dart';

class TurnoCreateScreen extends ConsumerStatefulWidget {
  const TurnoCreateScreen({super.key});

  static const routeName = '/turni/nuovo';

  @override
  ConsumerState<TurnoCreateScreen> createState() => _TurnoCreateScreenState();
}

class _TurnoCreateScreenState extends ConsumerState<TurnoCreateScreen> {
  final _taskController = TextEditingController();
  late Future<TurnoCreateData?> _future;
  bool _initializedArgs = false;

  String? get _turnoId {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is String && args.isNotEmpty ? args : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedArgs) {
      return;
    }
    _initializedArgs = true;
    _future = _loadData();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<TurnoCreateData?> _loadData() async {
    final data = await ref
        .read(turnoCreateFormProvider.notifier)
        .load(
          selectedCasaId: ActiveCasaScope.read(context).selectedCasaId,
          turnoId: _turnoId,
        );
    if (mounted) {
      _taskController.text = ref.read(turnoCreateFormProvider).task;
    }
    return data;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final controller = ref.read(turnoCreateFormProvider.notifier);
    final data = await _future;
    final result = await controller.submit(data);
    if (result == null || !mounted) return;
    Navigator.of(context).pushReplacementNamed(
      TurnoSalvatoConSuccessoScreen.routeName,
      arguments: TurnoSaveResultArguments(isEditing: result.isEditing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(turnoCreateFormProvider);
    final controller = ref.watch(turnoCreateFormProvider.notifier);
    final future = _future;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/turni'),
      body: FutureBuilder<TurnoCreateData?>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text(
                'Dati turno non disponibili.',
                style: TextStyle(color: AppColors.textOnDark),
              ),
            );
          }

          final assignees = data.assigneeChoices;
          final currentUser = data.currentInquilino;
          final isEditing = data.isEditing;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p9,
                AppSizes.p8,
                AppSizes.p9,
                AppSizes.p13,
              ),
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
                      isEditing ? 'Modifica turno' : 'Inserisci turno',
                      style: AppTextStyles.screenTitleStrong.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: AppSizes.p24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p17),
                    AppTaskField(
                      controller: _taskController,
                      hasError: form.showErrors && form.task.trim().isEmpty,
                      onChanged: controller.setTask,
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: AppSizes.p25),
                      _AssigneeSection(
                        inquilini: assignees,
                        canAssignOthers: ActiveCasaScope.of(
                          context,
                        ).isHomeAdmin,
                        currentUserId: currentUser?.id,
                        selectedId: form.selectedInquilinoId,
                        showError:
                            form.showErrors && form.selectedInquilinoId == null,
                        onSelected: controller.setAssignee,
                      ),
                      const SizedBox(height: AppSizes.p20),
                      _DateRow(
                        selectedDate: form.turnoDate,
                        hasError: form.showErrors && !form.hasValidDate,
                        onPickDate: () => _pickDate(form.turnoDate),
                      ),
                      if (form.showDatePastError) ...[
                        const SizedBox(height: AppSizes.p12),
                        const _ErrorLine(
                          message: 'Data errata: seleziona una data futura',
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSizes.p25),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSizes.p24),
                      child: Text(
                        'Frequenza',
                        style: AppTextStyles.screenTitleStrong.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                          fontSize: AppSizes.p21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p6),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p24,
                      ),
                      child: _FrequencyDropdown(
                        value: form.frequency,
                        expanded: form.frequencyExpanded,
                        hasError: form.showErrors && form.frequency.isEmpty,
                        onToggle: controller.toggleFrequency,
                        onChanged: controller.setFrequency,
                      ),
                    ),
                    SizedBox(height: form.frequencyExpanded ? 16 : 34),
                    Builder(
                      builder: (context) {
                        final canToggleRotation = ActiveCasaScope.of(
                          context,
                        ).isHomeAdmin;
                        return _AutoRotationRow(
                          value: form.autoRotation,
                          onChanged: canToggleRotation
                              ? controller.setAutoRotation
                              : (_) {},
                          enabled: canToggleRotation,
                        );
                      },
                    ),
                    if (form.showMissingError) ...[
                      const SizedBox(height: AppSizes.p18),
                      const _ErrorLine(
                        message: 'Dati mancanti: compila i campi necessari',
                      ),
                    ],
                    SizedBox(height: form.showMissingError ? 20 : 34),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p20,
                      ),
                      child: _SaveButton(
                        enabled: form.canSubmit,
                        submitting: form.isSubmitting,
                        onPressed: _submit,
                        label: isEditing ? 'Salva modifiche' : 'Salva turno',
                      ),
                    ),
                    const SizedBox(height: AppSizes.p7),
                    AppCancelButton(
                      enabled: !form.isSubmitting,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
    if (inquilini.isEmpty) {
      return const SizedBox.shrink();
    }

    final fallbackId = currentUserId?.trim().isNotEmpty == true
        ? currentUserId!.trim()
        : (inquilini.isNotEmpty ? inquilini.first.id : 'unknown-user-id');

    if (!canAssignOthers || inquilini.length <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
        child: _AssignMeButton(
          selected: selectedId == fallbackId,
          onTap: () => onSelected(fallbackId),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.p24, right: AppSizes.p24),
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
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: AppSizes.p20,
                ),
              ),
              const Spacer(),
              if (showError)
                Text(
                  '*',
                  style: AppTextStyles.input.copyWith(
                    color: AppColors.errorStrong,
                    fontSize: AppSizes.p23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(inquilini.length, (index) {
                final inquilino = inquilini[index];
                final label = _initials(inquilino);
                final selected = inquilino.id == selectedId;
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < inquilini.length - 1 ? AppSizes.p10 : 0,
                  ),
                  child: _AssigneeChip(
                    label: label,
                    username: inquilino.username,
                    color: userAvatarColorsForSeed(inquilino.id).background,
                    selected: selected,
                    showError: showError,
                    onTap: () => onSelected(inquilino.id),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(Inquilino inquilino) {
    final username = inquilino.username.trim();
    if (username.isNotEmpty) {
      return initialsFromText(username);
    }
    return resolveUserInitials(
      name: inquilino.nome,
      surname: inquilino.cognome,
      displayName: inquilino.nomeCompleto,
      fallback: '?',
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

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({
    required this.label,
    required this.username,
    required this.color,
    required this.selected,
    required this.showError,
    required this.onTap,
  });

  final String label;
  final String username;
  final Color color;
  final bool selected;
  final bool showError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = showError
        ? AppColors.errorStrong
        : selected
        ? AppColors.textOnDark
        : AppColors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.p56,
            height: AppSizes.p56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: AppSizes.p2_2),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: AppSizes.p10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          SizedBox(
            width: AppSizes.p64,
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: AppSizes.p11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      child: Container(
        height: AppSizes.p50,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: hasError ? AppColors.errorStrong : AppColors.transparent,
            width: AppSizes.p2_4,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p15,
          vertical: AppSizes.p10,
        ),
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
                          ? (selectedDate != null
                                ? AppColors.brandAccent
                                : AppColors.errorStrong)
                          : AppColors.textMutedLight,
                      size: AppSizes.p22,
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: (hasError || selectedDate != null)
                              ? (selectedDate != null
                                    ? AppColors.textOnDark
                                    : AppColors.errorStrong)
                              : AppColors.textMutedLight,
                          fontSize: AppSizes.p20,
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
            height: AppSizes.p49,
            decoration: BoxDecoration(
              color: expanded
                  ? AppColors.brandPrimary
                  : AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(AppSizes.radius8),
                bottom: Radius.circular(expanded ? 0 : AppSizes.radius8),
              ),
              border: hasError
                  ? Border.all(
                      color: AppColors.errorStrong,
                      width: AppSizes.p2_4,
                    )
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowStrong,
                  blurRadius: AppSizes.p5,
                  offset: Offset(0, AppSizes.p3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p17),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasError ? '$value      *' : value,
                    style: AppTextStyles.input.copyWith(
                      color: hasError
                          ? AppColors.errorStrong
                          : AppColors.textMutedLight,
                      fontSize: AppSizes.p20,
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
                  size: AppSizes.p28,
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
              children: TurnoCreateFormState.frequencies.map((option) {
                return InkWell(
                  onTap: () => onChanged(option),
                  child: Container(
                    height: AppSizes.p45,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p16,
                    ),
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
                        fontSize: AppSizes.p16,
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
  const _AutoRotationRow({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rotazione automatica assegnatario',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: enabled
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: AppSizes.p16,
                ),
              ),
              if (!enabled) ...[
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
        AppSwitch(
          value: value,
          onChanged: enabled ? onChanged : null,
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
        const SizedBox(width: AppSizes.p24),
        const Icon(
          Icons.error,
          color: AppColors.errorStrong,
          size: AppSizes.p21,
        ),
        const SizedBox(width: AppSizes.p3),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.error.copyWith(
              color: AppColors.errorStrong,
              fontSize: AppSizes.p16,
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
    required this.label,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        disabledBackgroundColor: AppColors.textMutedDark,
        foregroundColor: AppColors.textOnDark,
        disabledForegroundColor: AppColors.textOnDark,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius18),
        ),
      ),
      child: submitting
          ? const SizedBox(
              width: AppSizes.p23,
              height: AppSizes.p23,
              child: CircularProgressIndicator(
                color: AppColors.textOnDark,
                strokeWidth: 2.4,
              ),
            )
          : Text(
              label,
              style: AppTextStyles.buttonCompact.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
