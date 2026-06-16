import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_admin.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final modificaSpesaFormProvider =
    StateNotifierProvider.autoDispose<
      SpesaEditFormController,
      SpesaEditFormState
    >((_) => SpesaEditFormController());

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
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty || !mounted) return;

    final casa = activeCasaController.resolveCasa(caseUtente);
    final spesa = args is Spesa
        ? args
        : args is String
        ? await ApiProvider.spese.getById(casa.id, args)
        : null;
    if (spesa == null || !mounted) return;

    final inquilini = await ApiProvider.casa.listInquilini(casa.id);
    if (!mounted) return;

    final currentUserId = _resolveCurrentUserId(inquilini);
    controller.initFromSpesa(spesa, currentUserId, casa);

    final formState = ref.read(modificaSpesaFormProvider);
    _importoCtrl.text = formState.importo;
    _descCtrl.text = formState.descrizione;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ctrl = ref.read(modificaSpesaFormProvider.notifier);
    final form = ref.read(modificaSpesaFormProvider);
    if (!ctrl.validateBeforeSubmit()) return;
    if (form.casa == null) return;

    final casa = form.casa!;
    final spesaId = form.spesaId!;
    ctrl.setSubmitting(true);

    try {
      final inquilini = await ApiProvider.casa.listInquilini(casa.id);
      final currentUserId = _resolveCurrentUserId(inquilini);
      final partecipanti = _buildPartecipantiIds(
        selectedIds: form.selectedInquiliniIds,
        forceId: currentUserId,
      );
      final payload = <String, dynamic>{
        'descrizione': form.descrizione.trim(),
        'importo': double.parse(form.importo.replaceAll(',', '.')),
        'partecipanti': partecipanti,
        'isRicorrente': form.spesaRicorrente,
        if (form.dataSpesa != null) 'dataScadenza': _fmtDate(form.dataSpesa),
        if (form.hoAnticipatoPerTutti && currentUserId != null)
          'anticipataDa': currentUserId,
        if (form.spesaRicorrente) ...{
          'dataScadenza': _fmtDate(form.dataSpesa),
          'cadenzaGiorni': _cadenzaGiorniFor(form.frequenza),
        },
      };
      final updatedSpesa = await ApiProvider.spese.update(
        casa.id,
        spesaId,
        payload,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        DettaglioSpesaAdminScreen.routeName,
        arguments: updatedSpesa,
      );
    } catch (_) {
      ctrl.setSubmitError('Impossibile salvare le modifiche. Riprova.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(modificaSpesaFormProvider);
    final ctrl = ref.read(modificaSpesaFormProvider.notifier);

    final isAdmin = ActiveCasaScope.of(context).isHomeAdmin;

    final inquiliniAsync = form.casa == null
        ? const AsyncValue<List<Inquilino>>.loading()
        : ref.watch(_inquiliniProvider(form.casa!.id));

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: form.casa == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Spese',
                                  style: AppTextStyles.screenTitleStrong
                                      .copyWith(
                                        color: AppColors.brandAccent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Importo
                          SpesaFormImportoCard(
                            controller: _importoCtrl,
                            hasError: form.showErrors && !form.hasValidImporto,
                            onChanged: ctrl.setImporto,
                          ),
                          const SizedBox(height: 10),

                          // Data + Descrizione
                          Row(
                            children: [
                              SpesaFormDateField(
                                value: form.dataSpesa,
                                onChanged: ctrl.setDataSpesa,
                                onCleared: ctrl.clearDataSpesa,
                              ),
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 24),

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
                          const SizedBox(height: 20),

                          // Toggle panel
                          SpesaFormTogglePanel(
                            children: [
                              SpesaFormPaidForAllRow(
                                value: form.hoAnticipatoPerTutti,
                                onChanged: ctrl.setHoAnticipatoPerTutti,
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFF3A3555),
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
                            const SizedBox(height: 16),
                            Text(
                              'Frequenza',
                              style: AppTextStyles.screenTitleStrong.copyWith(
                                color: AppColors.brandPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SpesaFormFrequencyDropdown(
                              value: form.frequenza,
                              onChanged: ctrl.setFrequenza,
                            ),
                          ],

                          if (form.showMissingError) ...[
                            const SizedBox(height: 16),
                            SpesaFormErrorLine(message: form.submitError),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
            ),

            // CTA pinned
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: SpesaFormConfermaButton(
                label: 'Salva modifiche',
                enabled: form.canSubmit,
                submitting: form.isSubmitting,
                onPressed: _submit,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _AnnullaButton(
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

// ---------------------------------------------------------------------------
// Provider inquilini per casa (lazy)
// ---------------------------------------------------------------------------

final _inquiliniProvider = FutureProvider.autoDispose
    .family<List<Inquilino>, String>(
      (ref, casaId) => ApiProvider.casa.listInquilini(casaId),
    );

// ---------------------------------------------------------------------------
// Form State
// ---------------------------------------------------------------------------

class SpesaEditFormState {
  const SpesaEditFormState({
    this.importo = '',
    this.descrizione = '',
    this.selectedInquiliniIds = const {},
    this.creatoreId,
    this.dataSpesa,
    this.hoAnticipatoPerTutti = false,
    this.spesaRicorrente = false,
    this.frequenza = 'Mensile',
    this.showErrors = false,
    this.isSubmitting = false,
    this.submitError = '',
    this.casa,
    this.spesaId,
  });

  final String importo;
  final String descrizione;
  final Set<String> selectedInquiliniIds;
  final String? creatoreId;
  final DateTime? dataSpesa;
  final bool hoAnticipatoPerTutti;
  final bool spesaRicorrente;
  final String frequenza;
  final bool showErrors;
  final bool isSubmitting;
  final String submitError;
  final Casa? casa;
  final String? spesaId;

  DateTime get effectiveDate => dataSpesa ?? DateTime.now();

  bool get hasValidImporto =>
      importo.trim().isNotEmpty &&
      (double.tryParse(importo.trim().replaceAll(',', '.')) ?? 0) > 0;

  bool get canSubmit =>
      hasValidImporto &&
      descrizione.trim().isNotEmpty &&
      selectedInquiliniIds.isNotEmpty &&
      !isSubmitting &&
      casa != null;

  bool get showMissingError => submitError.isNotEmpty && showErrors;

  SpesaEditFormState copyWith({
    String? importo,
    String? descrizione,
    Set<String>? selectedInquiliniIds,
    String? creatoreId,
    DateTime? dataSpesa,
    bool clearDataSpesa = false,
    bool? hoAnticipatoPerTutti,
    bool? spesaRicorrente,
    String? frequenza,
    bool? showErrors,
    bool? isSubmitting,
    String? submitError,
    Casa? casa,
    String? spesaId,
  }) {
    return SpesaEditFormState(
      importo: importo ?? this.importo,
      descrizione: descrizione ?? this.descrizione,
      selectedInquiliniIds: selectedInquiliniIds ?? this.selectedInquiliniIds,
      creatoreId: creatoreId ?? this.creatoreId,
      dataSpesa: clearDataSpesa ? null : (dataSpesa ?? this.dataSpesa),
      hoAnticipatoPerTutti: hoAnticipatoPerTutti ?? this.hoAnticipatoPerTutti,
      spesaRicorrente: spesaRicorrente ?? this.spesaRicorrente,
      frequenza: frequenza ?? this.frequenza,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError ?? this.submitError,
      casa: casa ?? this.casa,
      spesaId: spesaId ?? this.spesaId,
    );
  }
}

// ---------------------------------------------------------------------------
// Form Controller
// ---------------------------------------------------------------------------

class SpesaEditFormController extends StateNotifier<SpesaEditFormState> {
  SpesaEditFormController() : super(const SpesaEditFormState());

  void initFromSpesa(Spesa spesa, String? currentUserId, Casa casa) {
    // Partecipanti da spesa
    final selectedIds = <String>{};
    for (final p in spesa.partecipanti) {
      final id =
          p['id']?.toString() ??
          p['idUtente']?.toString() ??
          p['userId']?.toString() ??
          '';
      if (id.isNotEmpty) selectedIds.add(id);
    }
    // Il creatore è sempre incluso
    if (spesa.creatoreId.isNotEmpty) selectedIds.add(spesa.creatoreId);
    if (currentUserId != null && currentUserId.isNotEmpty) {
      selectedIds.add(currentUserId);
    }

    final importoStr = spesa.importo > 0
        ? spesa.importo.toStringAsFixed(2).replaceAll('.', ',')
        : '';

    final cadenza = spesa.raw['cadenzaGiorni'];
    final frequenza = _frequenzaFromCadenza(cadenza);

    final anticipataDa = spesa.raw['anticipataDa'];
    final hoAnticipato =
        anticipataDa != null && anticipataDa.toString().isNotEmpty;

    final creatoreId = spesa.creatoreId.isNotEmpty
        ? spesa.creatoreId
        : currentUserId;

    state = state.copyWith(
      importo: importoStr,
      descrizione: spesa.descrizione,
      dataSpesa: spesa.dataScadenza,
      selectedInquiliniIds: selectedIds,
      creatoreId: creatoreId,
      hoAnticipatoPerTutti: hoAnticipato,
      spesaRicorrente: spesa.isRicorrente,
      frequenza: frequenza,
      casa: casa,
      spesaId: spesa.id,
    );
  }

  void setImporto(String v) =>
      state = state.copyWith(importo: v, submitError: '');
  void setDescrizione(String v) =>
      state = state.copyWith(descrizione: v, submitError: '');
  void setDataSpesa(DateTime v) => state = state.copyWith(dataSpesa: v);
  void clearDataSpesa() => state = state.copyWith(clearDataSpesa: true);
  void setHoAnticipatoPerTutti(bool v) =>
      state = state.copyWith(hoAnticipatoPerTutti: v);
  void setSpesaRicorrente(bool v) => state = state.copyWith(spesaRicorrente: v);
  void setFrequenza(String v) => state = state.copyWith(frequenza: v);

  void toggleInquilino(String id) {
    // Il creatore non può essere rimosso
    if (id == state.creatoreId) return;
    final ids = {...state.selectedInquiliniIds};
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(selectedInquiliniIds: ids, submitError: '');
  }

  bool validateBeforeSubmit() {
    if (!state.hasValidImporto ||
        state.descrizione.trim().isEmpty ||
        state.selectedInquiliniIds.isEmpty) {
      state = state.copyWith(
        showErrors: true,
        submitError: 'Dati mancanti: compila i campi necessari',
      );
      return false;
    }
    return true;
  }

  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  void setSubmitError(String e) => state = state.copyWith(
    submitError: e,
    showErrors: true,
    isSubmitting: false,
  );
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

  String get _displayAmount {
    final raw = widget.controller.text.trim().replaceAll(',', '.');
    final n = double.tryParse(raw);
    if (n == null || n == 0) return '€ 0,00';
    return '€ ${n.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: widget.hasError
                ? AppColors.statusNegative
                : _isFocused
                ? AppColors.brandAccent
                : Colors.white.withValues(alpha: 0.28),
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
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
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
                      fontSize: 32,
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
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                      hintStyle: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.brandAccent.withValues(alpha: 0.35),
                        fontSize: 32,
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
                surface: Color(0xFF1E1A30),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: hasDate
                ? AppColors.brandPrimary.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.brandPrimary,
              size: 15,
            ),
            const SizedBox(width: 5),
            if (hasDate) ...[
              Text(
                _fmtDate(value!),
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onCleared != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onCleared,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: AppColors.textOnDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ] else ...[
              Text(
                'Scadenza',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.38),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(opz.)',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.25),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Tooltip(
              message: _tooltip,
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2846),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4A4370), width: 1),
              ),
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Inter',
                height: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(
                Icons.info_outline_rounded,
                size: 14,
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
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Descrizione spesa',
        hintStyle: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: hasError ? AppColors.statusNegative : Colors.transparent,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: hasError
                ? AppColors.statusNegative
                : Colors.white.withValues(alpha: 0.28),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: const BorderSide(color: AppColors.brandAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
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
      height: 120,
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
            color: const Color(0xFFCBB8FF),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            border: Border.all(
              color: showError
                  ? AppColors.statusNegative
                  : Colors.white.withValues(alpha: 0.28),
              width: 1.5,
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
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: Color(0xFF2E2A42),
                  ),
              ],
            ],
          ),
        ),
        if (showError) ...[
          const SizedBox(height: 8),
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
      Color(0xFF1B5E20),
      Color(0xFFE53935),
      Color(0xFF6D4C41),
      Color(0xFF1565C0),
      Color(0xFF6A1B9A),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: isLocked
                      ? AppColors.textOnDark.withValues(alpha: 0.62)
                      : AppColors.textOnDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (quota != null && isSelected) ...[
              Text(
                '€ ${quota!.toStringAsFixed(2).replaceAll('.', ',')}',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (!isLocked) ...[
              Text(
                '−',
                style: TextStyle(
                  color: AppColors.textOnDark.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: isSelected,
                onChanged: isLocked ? null : (_) => onTap(),
                activeColor: AppColors.brandPrimary,
                checkColor: Colors.white,
                side: BorderSide(
                  color: isLocked
                      ? AppColors.textOnDark.withValues(alpha: 0.2)
                      : AppColors.textOnDark.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
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
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.5,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gli altri vedranno il debito verso di te',
                  style: TextStyle(
                    color: AppColors.textOnDark.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.brandPrimary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF3A3555),
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFF7B5DC8),
                );
              }
              return const Icon(
                Icons.close_rounded,
                size: 14,
                color: Color(0xFF888888),
              );
            }),
          ),
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
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        'Ripete seguendo la data precedente',
                        style: TextStyle(
                          color: AppColors.textOnDark.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (!isAdmin)
                        const Text(
                          '( solo HomeAdmin ) ⚠',
                          style: TextStyle(
                            color: AppColors.lockOrange,
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.brandPrimary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF3A3555),
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF7B5DC8),
                  );
                }
                return const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Color(0xFF888888),
                );
              }),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      opt,
                      style: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.textOnDark,
                        fontSize: 15,
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
                      fontSize: 15,
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
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.statusNegative,
              fontSize: 13,
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

  static const _radius = BorderRadius.all(Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: enabled && !submitting
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF9B7FE8),
                    Color(0xFF7B5DC8),
                    Color(0xFF5C3FA8),
                  ],
                  stops: [0.0, 0.55, 1.0],
                )
              : const LinearGradient(
                  colors: [Color(0xFF4A4560), Color(0xFF3A3555)],
                ),
          shape: const RoundedRectangleBorder(borderRadius: _radius),
          shadows: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: enabled && !submitting ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: _radius),
            elevation: 0,
          ),
          child: Text(
            submitting ? 'Salvataggio...' : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Annulla button
// ---------------------------------------------------------------------------

class _AnnullaButton extends StatelessWidget {
  const _AnnullaButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.statusNegative,
          side: const BorderSide(color: AppColors.statusNegative, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          disabledForegroundColor: AppColors.statusNegative.withValues(
            alpha: 0.4,
          ),
        ),
        child: const Text(
          'Annulla',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String? _resolveCurrentUserId(List<Inquilino> inquilini) {
  final userId = ApiProvider.client.currentUserId;
  if (userId != null && userId.trim().isNotEmpty) return userId.trim();
  final email = ApiProvider.client.currentUserEmail?.trim().toLowerCase();
  final name = ApiProvider.client.currentUserName?.trim().toLowerCase();
  for (final inq in inquilini) {
    final values = [
      inq.email,
      inq.username,
      inq.nome,
      inq.nomeCompleto,
    ].map((v) => v.trim().toLowerCase());
    if ((email != null && values.contains(email)) ||
        (name != null && values.contains(name))) {
      return inq.id;
    }
  }
  return inquilini.isNotEmpty ? inquilini.first.id : null;
}

List<String> _buildPartecipantiIds({
  required Set<String> selectedIds,
  required String? forceId,
}) {
  final set = <String>{...selectedIds};
  if (forceId != null && forceId.isNotEmpty) set.add(forceId);
  return set.toList();
}

int _cadenzaGiorniFor(String frequenza) => switch (frequenza) {
  'Bimestrale' => 60,
  'Trimestrale' => 90,
  'Annuale' => 365,
  _ => 30,
};

String _frequenzaFromCadenza(dynamic cadenza) {
  final n = cadenza is num ? cadenza.toInt() : int.tryParse('$cadenza') ?? 30;
  return switch (n) {
    60 => 'Bimestrale',
    90 => 'Trimestrale',
    365 => 'Annuale',
    _ => 'Mensile',
  };
}

String _fmtDate(DateTime? d) =>
    (d ?? DateTime.now()).toIso8601String().split('T').first;
