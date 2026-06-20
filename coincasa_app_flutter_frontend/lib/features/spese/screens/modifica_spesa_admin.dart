import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_admin.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ModificaSpesaAdminScreen extends ConsumerStatefulWidget {
  const ModificaSpesaAdminScreen({super.key});

  static const String routeName = '/spese/modifica';

  @override
  ConsumerState<ModificaSpesaAdminScreen> createState() =>
      _ModificaSpesaAdminScreenState();
}

class _ModificaSpesaAdminScreenState
    extends ConsumerState<ModificaSpesaAdminScreen> {
  final _importoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initForm();
  }

  @override
  void dispose() {
    _importoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _initForm() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final controller = ref.read(modificaSpesaFormProvider.notifier);

    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ref.read(listaCaseViewModelProvider.future);
    if (caseUtente.isEmpty || !mounted) return;

    final casa = activeCasaController.resolveCasa(caseUtente);
    final spesa = args is Spesa
        ? args
        : args is String
        ? await ref
              .read(speseViewModelProvider(casa.id).notifier)
              .getSpesaById(args)
        : null;
    if (spesa == null || !mounted) return;

    final state = await ref.read(speseViewModelProvider(casa.id).future);
    final inquilini = state.inquilini;
    if (!mounted) return;

    final currentUser = ref.read(authViewModelProvider).valueOrNull;
    final currentUserId = resolveCurrentUserId(inquilini, currentUser);
    controller.initFromSpesa(spesa, currentUserId, casa);

    final formState = ref.read(modificaSpesaFormProvider);
    _importoCtrl.text = formState.importo;
    _descCtrl.text = formState.descrizione;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ctrl = ref.read(modificaSpesaFormProvider.notifier);
    final form = ref.read(modificaSpesaFormProvider);
    if (form.casa == null) return;

    final casa = form.casa!;
    final state = await ref.read(speseViewModelProvider(casa.id).future);
    final updatedSpesa = await ctrl.submit(
      inquilini: state.inquilini,
      currentUser: ref.read(authViewModelProvider).valueOrNull,
    );
    if (updatedSpesa == null || !mounted) return;
    Navigator.of(context).pushReplacementNamed(
      DettaglioSpesaAdminScreen.routeName,
      arguments: updatedSpesa,
    );
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(modificaSpesaFormProvider);
    final ctrl = ref.watch(modificaSpesaFormProvider.notifier);

    final isAdmin = ActiveCasaScope.of(context).isHomeAdmin;

    final inquiliniAsync = form.casa == null
        ? const AsyncValue<List<Inquilino>>.loading()
        : ref.watch(spesaEditInquiliniProvider(form.casa!.id));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: form.casa == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.p16,
                        AppSizes.p16,
                        AppSizes.p16,
                        AppSizes.p16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Breadcrumb
                          GestureDetector(
                            onTap: () =>
                                Navigator.of(context).pushReplacementNamed(
                                  ListaSpeseAdminScreen.routeName,
                                ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.brandAccent,
                                  size: AppSizes.p16,
                                ),
                                const SizedBox(width: AppSizes.p4),
                                Text(
                                  'Spese',
                                  style: AppTextStyles.screenTitleStrong
                                      .copyWith(
                                        color: AppColors.brandAccent,
                                        fontSize: AppSizes.p16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.p16),

                          // Importo
                          SpesaFormImportoCard(
                            controller: _importoCtrl,
                            hasError: form.showErrors && !form.hasValidImporto,
                            onChanged: ctrl.setImporto,
                          ),
                          const SizedBox(height: AppSizes.p10),

                          // Data + Descrizione
                          Row(
                            children: [
                              SpesaFormDateField(
                                value: form.dataSpesa,
                                onChanged: ctrl.setDataSpesa,
                                onCleared: ctrl.clearDataSpesa,
                              ),
                              const SizedBox(width: AppSizes.p8),
                              Expanded(
                                child: SpesaFormDescrizioneField(
                                  controller: _descCtrl,
                                  hasError:
                                      form.showErrors &&
                                      form.descrizione.trim().isEmpty,
                                  onChanged: ctrl.setDescrizione,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.p24),

                          // Dividi tra
                          inquiliniAsync.when(
                            loading: () => const SpesaFormDivisioneLoading(),
                            error: (_, _) => SpesaFormDivisioneSection(
                              inquilini: const [],
                              selectedIds: form.selectedInquiliniIds,
                              lockedId: form.creatoreId,
                              importo: form.importo,
                              showError:
                                  form.showErrors &&
                                  form.selectedInquiliniIds.isEmpty,
                              onSelected: ctrl.toggleInquilino,
                            ),
                            data: (inquilini) => SpesaFormDivisioneSection(
                              inquilini: inquilini,
                              selectedIds: form.selectedInquiliniIds,
                              lockedId: form.creatoreId,
                              importo: form.importo,
                              showError:
                                  form.showErrors &&
                                  form.selectedInquiliniIds.isEmpty,
                              onSelected: ctrl.toggleInquilino,
                            ),
                          ),
                          const SizedBox(height: AppSizes.p20),

                          // Toggle panel
                          SpesaFormTogglePanel(
                            children: [
                              SpesaFormPaidForAllRow(
                                value: form.hoAnticipatoPerTutti,
                                onChanged: ctrl.setHoAnticipatoPerTutti,
                              ),
                              const Divider(
                                height: AppSizes.p1,
                                color: AppColors.dividerDark,
                              ),
                              SpesaFormRecurringRow(
                                value: form.spesaRicorrente,
                                isAdmin: isAdmin,
                                onChanged: isAdmin
                                    ? ctrl.setSpesaRicorrente
                                    : null,
                              ),
                            ],
                          ),

                          // Frequenza
                          if (isAdmin && form.spesaRicorrente) ...[
                            const SizedBox(height: AppSizes.p16),
                            Text(
                              'Frequenza',
                              style: AppTextStyles.screenTitleStrong.copyWith(
                                color: AppColors.brandPrimary,
                                fontSize: AppSizes.p15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSizes.p8),
                            SpesaFormFrequencyDropdown(
                              value: form.frequenza,
                              onChanged: ctrl.setFrequenza,
                            ),
                          ],

                          if (form.showMissingError) ...[
                            const SizedBox(height: AppSizes.p16),
                            SpesaFormErrorLine(message: form.submitError),
                          ],
                          const SizedBox(height: AppSizes.p8),
                        ],
                      ),
                    ),
            ),

            // CTA pinned
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p8,
                AppSizes.p16,
                AppSizes.p6,
              ),
              child: SpesaFormConfermaButton(
                label: 'Salva modifiche',
                enabled: form.canSubmit,
                submitting: form.isSubmitting,
                onPressed: _submit,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p0,
                AppSizes.p16,
                AppSizes.p14,
              ),
              child: AppCancelButton(
                enabled: !form.isSubmitting,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED FORM WIDGETS — usati anche da InserisciSpesaScreen
// ============================================================================

// ---------------------------------------------------------------------------
// Importo card
// ---------------------------------------------------------------------------

class SpesaFormImportoCard extends StatefulWidget {
  const SpesaFormImportoCard({
    super.key,
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  State<SpesaFormImportoCard> createState() => _SpesaFormImportoCardState();
}

class _SpesaFormImportoCardState extends State<SpesaFormImportoCard> {
  final _focus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p14,
          AppSizes.p12,
          AppSizes.p14,
          AppSizes.p12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: widget.hasError
                ? AppColors.statusNegative
                : _isFocused
                ? AppColors.brandAccent
                : AppColors.textOnDark.withValues(alpha: 0.28),
            width: _isFocused ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Importo',
              style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.75),
                fontSize: AppSizes.p13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.p4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(13)],
                    textAlign: TextAlign.right,
                    cursorColor: AppColors.brandPrimary,
                    onChanged: widget.onChanged,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.brandAccent,
                      fontSize: AppSizes.p32,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0,00',
                      prefixText: '€ ',
                      prefixStyle: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.brandAccent,
                        fontSize: AppSizes.p32,
                        fontWeight: FontWeight.w800,
                      ),
                      hintStyle: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.brandAccent.withValues(alpha: 0.35),
                        fontSize: AppSizes.p32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date field
// ---------------------------------------------------------------------------

class SpesaFormDateField extends StatelessWidget {
  const SpesaFormDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.onCleared,
    this.minDate,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onCleared;
  final DateTime? minDate;

  static const _tooltip =
      'Data entro cui la spesa deve essere pagata.\n'
      'Es. bolletta elettrica da pagare entro il 15 luglio.';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasDate = value != null;

    return GestureDetector(
      onTap: () async {
        final today = DateTime.now();
        final effectiveMin = minDate ?? DateTime(2020);
        final effectiveInitial = value != null
            ? (value!.isBefore(effectiveMin) ? effectiveMin : value!)
            : (today.isBefore(effectiveMin) ? effectiveMin : today);
        final picked = await showDatePicker(
          context: context,
          initialDate: effectiveInitial,
          firstDate: effectiveMin,
          lastDate: DateTime(2035),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.brandPrimary,
                surface: AppColors.surfaceDarkCard,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p10,
          vertical: AppSizes.p10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: hasDate
                ? AppColors.brandPrimary.withValues(alpha: 0.6)
                : AppColors.textOnDark.withValues(alpha: 0.18),
            width: AppSizes.p1_5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.brandPrimary,
              size: AppSizes.p15,
            ),
            const SizedBox(width: AppSizes.p5),
            if (hasDate) ...[
              Text(
                _fmtDate(value!),
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: AppSizes.p13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onCleared != null) ...[
                const SizedBox(width: AppSizes.p4),
                GestureDetector(
                  onTap: onCleared,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.close_rounded,
                    size: AppSizes.p15,
                    color: AppColors.textOnDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ] else ...[
              Text(
                'Scadenza',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.38),
                  fontSize: AppSizes.p13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSizes.p4),
              Text(
                '(opz.)',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.25),
                  fontSize: AppSizes.p11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            const SizedBox(width: AppSizes.p4),
            Tooltip(
              message: _tooltip,
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkMuted,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
                border: Border.all(
                  color: AppColors.dividerOnDark,
                  width: AppSizes.p1,
                ),
              ),
              textStyle: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p12,
                height: AppSizes.p1_5,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p8,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: AppSizes.p14,
                color: AppColors.textOnDark.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Descrizione field
// ---------------------------------------------------------------------------

class SpesaFormDescrizioneField extends StatelessWidget {
  const SpesaFormDescrizioneField({
    super.key,
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
      style: AppTextStyles.screenTitleStrong.copyWith(
        color: AppColors.textOnDark,
        fontSize: AppSizes.p14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Descrizione spesa',
        hintStyle: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.4),
          fontSize: AppSizes.p14,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: hasError ? AppColors.statusNegative : AppColors.transparent,
            width: AppSizes.p1_5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: hasError
                ? AppColors.statusNegative
                : AppColors.textOnDark.withValues(alpha: 0.28),
            width: AppSizes.p1_5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: const BorderSide(
            color: AppColors.brandAccent,
            width: AppSizes.p2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p13,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divisione section
// ---------------------------------------------------------------------------

class SpesaFormDivisioneLoading extends StatelessWidget {
  const SpesaFormDivisioneLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AppSizes.p120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class SpesaFormDivisioneSection extends StatelessWidget {
  const SpesaFormDivisioneSection({
    super.key,
    required this.inquilini,
    required this.selectedIds,
    required this.lockedId, // sempre selezionato, non rimovibile
    required this.importo,
    required this.showError,
    required this.onSelected,
  });

  final List<Inquilino> inquilini;
  final Set<String> selectedIds;
  final String? lockedId;
  final String importo;
  final bool showError;
  final ValueChanged<String> onSelected;

  double? get _quotaPerPerson {
    if (selectedIds.isEmpty) return null;
    final total = double.tryParse(importo.trim().replaceAll(',', '.'));
    if (total == null || total <= 0) return null;
    return total / selectedIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final quota = _quotaPerPerson;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DIVIDI TRA',
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.brandAccent,
            fontSize: AppSizes.p13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSizes.p10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            border: Border.all(
              color: showError
                  ? AppColors.statusNegative
                  : AppColors.textOnDark.withValues(alpha: 0.28),
              width: AppSizes.p1_5,
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < inquilini.length; i++) ...[
                SpesaFormInquilinoRow(
                  inquilino: inquilini[i],
                  isSelected: selectedIds.contains(inquilini[i].id),
                  isLocked: inquilini[i].id == lockedId,
                  quota: selectedIds.contains(inquilini[i].id) ? quota : null,
                  onTap: () => onSelected(inquilini[i].id),
                ),
                if (i < inquilini.length - 1)
                  const Divider(
                    height: AppSizes.p1,
                    indent: 14,
                    endIndent: 14,
                    color: AppColors.surfaceDarkMuted,
                  ),
              ],
            ],
          ),
        ),
        if (showError) ...[
          const SizedBox(height: AppSizes.p8),
          const SpesaFormErrorLine(message: 'Seleziona almeno un coinquilino'),
        ],
      ],
    );
  }
}

class SpesaFormInquilinoRow extends StatelessWidget {
  const SpesaFormInquilinoRow({
    super.key,
    required this.inquilino,
    required this.isSelected,
    required this.isLocked,
    required this.quota,
    required this.onTap,
  });

  final Inquilino inquilino;
  final bool isSelected;
  final bool isLocked; // creatore — sempre spuntato, non cliccabile
  final double? quota;
  final VoidCallback onTap;

  Color _avatarColor(String id) {
    const colors = [
      AppColors.success,
      AppColors.error,
      AppColors.turniAssigneeMenuSurface,
      AppColors.info,
      AppColors.brandPrimary,
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final label = isLocked ? '${inquilino.username} (Tu)' : inquilino.username;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p10,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _avatarColor(inquilino.id),
              radius: 17,
              child: Text(
                resolveUserInitials(
                  displayName: inquilino.username.isNotEmpty
                      ? inquilino.username
                      : inquilino.email,
                  fallback: '?',
                ),
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: AppSizes.p13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: isLocked
                      ? AppColors.textOnDark.withValues(alpha: 0.62)
                      : AppColors.textOnDark,
                  fontSize: AppSizes.p15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p8),
            if (quota != null && isSelected) ...[
              Text(
                '€ ${quota!.toStringAsFixed(2).replaceAll('.', ',')}',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: AppSizes.p14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSizes.p8),
            ] else if (!isLocked) ...[
              Text(
                '−',
                style: TextStyle(
                  color: AppColors.textOnDark.withValues(alpha: 0.5),
                  fontSize: AppSizes.p14,
                ),
              ),
              const SizedBox(width: AppSizes.p8),
            ],
            SizedBox(
              width: AppSizes.p22,
              height: AppSizes.p22,
              child: Checkbox(
                value: isSelected,
                onChanged: isLocked ? null : (_) => onTap(),
                activeColor: AppColors.brandPrimary,
                checkColor: AppColors.textOnDark,
                side: BorderSide(
                  color: isLocked
                      ? AppColors.textOnDark.withValues(alpha: 0.2)
                      : AppColors.textOnDark.withValues(alpha: 0.4),
                  width: AppSizes.p1_5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius4),
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
// Toggle panel
// ---------------------------------------------------------------------------

class SpesaFormTogglePanel extends StatelessWidget {
  const SpesaFormTogglePanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(
          color: AppColors.textOnDark.withValues(alpha: 0.28),
          width: AppSizes.p1_5,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class SpesaFormPaidForAllRow extends StatelessWidget {
  const SpesaFormPaidForAllRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p14,
        AppSizes.p12,
        AppSizes.p10,
        AppSizes.p12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ho anticipato per tutti',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.textOnDark,
                    fontSize: AppSizes.p15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.p2),
                Text(
                  'Gli altri vedranno il debito verso di te',
                  style: TextStyle(
                    color: AppColors.textOnDark.withValues(alpha: 0.5),
                    fontSize: AppSizes.p12,
                  ),
                ),
              ],
            ),
          ),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class SpesaFormRecurringRow extends StatelessWidget {
  const SpesaFormRecurringRow({
    super.key,
    required this.value,
    required this.isAdmin,
    required this.onChanged,
  });

  final bool value;
  final bool isAdmin;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAdmin ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p14,
          AppSizes.p12,
          AppSizes.p10,
          AppSizes.p12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spesa ricorrente',
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: AppSizes.p15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        'Ripete seguendo la data precedente',
                        style: TextStyle(
                          color: AppColors.textOnDark.withValues(alpha: 0.5),
                          fontSize: AppSizes.p12,
                        ),
                      ),
                      if (!isAdmin)
                        const Text(
                          '( solo HomeAdmin ) ⚠',
                          style: TextStyle(
                            color: AppColors.lockOrange,
                            fontSize: AppSizes.p11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            AppSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Frequency dropdown
// ---------------------------------------------------------------------------

class SpesaFormFrequencyDropdown extends StatelessWidget {
  const SpesaFormFrequencyDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _options = [
    'Mensile',
    'Bimestrale',
    'Trimestrale',
    'Annuale',
    'Personalizzata',
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _options.contains(value) ? value : _options.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppColors.surfaceDarkElevated,
          iconEnabledColor: AppColors.brandPrimary,
          items: _options
              .map(
                (opt) => DropdownMenuItem(
                  value: opt,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p10),
                    child: Text(
                      opt,
                      style: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.textOnDark,
                        fontSize: AppSizes.p15,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (_) => _options
              .map(
                (opt) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    opt,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: AppSizes.p15,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error line
// ---------------------------------------------------------------------------

class SpesaFormErrorLine extends StatelessWidget {
  const SpesaFormErrorLine({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.warning_rounded,
          color: AppColors.statusNegative,
          size: AppSizes.p18,
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.statusNegative,
              fontSize: AppSizes.p13,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CTA button (viola, pill)
// ---------------------------------------------------------------------------

class SpesaFormConfermaButton extends StatelessWidget {
  const SpesaFormConfermaButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.submitting,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;

  static const _radius = BorderRadius.all(Radius.circular(AppSizes.radius28));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.p52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: enabled && !submitting
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.brandSecondary,
                    AppColors.brandSecondary,
                    AppColors.brandPrimaryDark,
                  ],
                  stops: [0.0, 0.55, 1.0],
                )
              : const LinearGradient(
                  colors: [AppColors.dividerOnDark, AppColors.dividerDark],
                ),
          shape: const RoundedRectangleBorder(borderRadius: _radius),
          shadows: const [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: AppSizes.p6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: enabled && !submitting ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.transparent,
            foregroundColor: AppColors.transparent,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: _radius),
            elevation: 0,
          ),
          child: Text(
            submitting ? 'Salvataggio...' : label,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
