import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/features/spese/screens/modifica_spesa_admin.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';

// ---------------------------------------------------------------------------
// Screen — full page
// ---------------------------------------------------------------------------

class InserisciSpesaScreen extends ConsumerStatefulWidget {
  const InserisciSpesaScreen({super.key});

  static const String routeName = '/spese/nuovo';

  @override
  ConsumerState<InserisciSpesaScreen> createState() =>
      _InserisciSpesaScreenState();
}

class _InserisciSpesaScreenState extends ConsumerState<InserisciSpesaScreen> {
  final _importoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _importoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final controller = ref.read(speseCreateFormProvider.notifier);
    final activeCasaController = ActiveCasaScope.of(context);
    final casa = await ref.read(
      speseCreateCasaProvider(activeCasaController.selectedCasaId).future,
    );
    final inquilini = casa == null
        ? const <Inquilino>[]
        : await ref.read(speseCreateInquiliniProvider(casa.id).future);
    final result = await controller.submit(
      casa: casa,
      inquilini: inquilini,
      currentUser: ref.read(authViewModelProvider).valueOrNull,
    );
    if (result == null || !mounted) return;

    final form = ref.read(speseCreateFormProvider);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _SpesaAggiuntaDialog(
        descrizione: result.spesa.descrizione,
        importo: result.importo,
        nPartecipanti: result.numeroPartecipanti,
        haAnticipato: form.hoAnticipatoPerTutti,
        anticipatoreNome: result.anticipatoreNome,
        onTornaAlleSpese: () {
          Navigator.of(dialogCtx).pop();
          Navigator.of(context).pushNamedAndRemoveUntil(
            ListaSpeseAdminScreen.routeName,
            (_) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.of(context);
    final form = ref.watch(speseCreateFormProvider);
    final controller = ref.watch(speseCreateFormProvider.notifier);
    final currentUser = ref.watch(authViewModelProvider).valueOrNull;
    final casaAsync = ref.watch(
      speseCreateCasaProvider(activeCasaController.selectedCasaId),
    );
    final isAdmin = activeCasaController.isHomeAdmin;
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(speseCreateInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (e, s) => AsyncValue<List<Inquilino>>.error(e, s),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                        onTap: () => Navigator.of(context).pop(),
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
                              style: AppTextStyles.screenTitleStrong.copyWith(
                                color: AppColors.brandAccent,
                                fontSize: AppSizes.p16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.p16),

                      // Importo — shared widget
                      SpesaFormImportoCard(
                        controller: _importoCtrl,
                        hasError: form.showErrors && !form.hasValidImporto,
                        onChanged: controller.setImporto,
                      ),
                      const SizedBox(height: AppSizes.p10),

                      // Data + Descrizione — shared widgets
                      Row(
                        children: [
                          SpesaFormDateField(
                            value: form.dataSpesa,
                            onChanged: controller.setDataSpesa,
                            onCleared: () => controller.clearDataSpesa(),
                            minDate: DateTime.now(),
                          ),
                          const SizedBox(width: AppSizes.p8),
                          Expanded(
                            child: SpesaFormDescrizioneField(
                              controller: _descCtrl,
                              hasError:
                                  form.showErrors &&
                                  form.descrizione.trim().isEmpty,
                              onChanged: controller.setDescrizione,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.p24),

                      // Dividi tra — shared widget
                      inquiliniAsync.when(
                        loading: () => const SpesaFormDivisioneLoading(),
                        error: (_, _) => SpesaFormDivisioneSection(
                          inquilini: const [],
                          selectedIds: form.selectedInquiliniIds,
                          lockedId: form.currentUserId,
                          importo: form.importo,
                          showError:
                              form.showErrors &&
                              form.selectedInquiliniIds.isEmpty,
                          onSelected: controller.toggleInquilino,
                        ),
                        data: (inquilini) {
                          final currentUserId = resolveCurrentUserId(
                            inquilini,
                            currentUser,
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            controller.prepopulateInquilini(
                              inquilini,
                              currentUserId,
                            );
                          });
                          return SpesaFormDivisioneSection(
                            inquilini: inquilini,
                            selectedIds: form.selectedInquiliniIds,
                            lockedId: currentUserId,
                            importo: form.importo,
                            showError:
                                form.showErrors &&
                                form.selectedInquiliniIds.isEmpty,
                            onSelected: controller.toggleInquilino,
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.p20),

                      // Toggle panel — shared widgets
                      SpesaFormTogglePanel(
                        children: [
                          SpesaFormPaidForAllRow(
                            value: form.hoAnticipatoPerTutti,
                            onChanged: controller.setHoAnticipatoPerTutti,
                          ),
                          const Divider(
                            height: AppSizes.p1,
                            color: AppColors.dividerDark,
                          ),
                          SpesaFormRecurringRow(
                            value: form.spesaRicorrente,
                            isAdmin: isAdmin,
                            onChanged: isAdmin
                                ? controller.setSpesaRicorrente
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
                          onChanged: controller.setFrequenza,
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

              // CTA pinned — shared widget
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p16,
                  AppSizes.p8,
                  AppSizes.p16,
                  AppSizes.p8,
                ),
                child: SpesaFormConfermaButton(
                  label: 'Conferma e aggiungi',
                  enabled: form.canSubmit,
                  submitting: form.isSubmitting,
                  onPressed: _submit,
                ),
              ),
              AppCancelButton(
                onPressed: form.isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSizes.p14),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popup version — stile originale con TextEditingController
// ---------------------------------------------------------------------------

class InserisciSpesaPopupContent extends ConsumerStatefulWidget {
  const InserisciSpesaPopupContent({super.key});

  @override
  ConsumerState<InserisciSpesaPopupContent> createState() =>
      _InserisciSpesaPopupContentState();
}

class _InserisciSpesaPopupContentState
    extends ConsumerState<InserisciSpesaPopupContent> {
  final _descrizioneController = TextEditingController();

  @override
  void dispose() {
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final controller = ref.read(speseCreateFormProvider.notifier);
    final navigator = Navigator.of(context);
    final activeCasaController = ActiveCasaScope.of(context);
    final casa = await ref.read(
      speseCreateCasaProvider(activeCasaController.selectedCasaId).future,
    );
    final inquilini = casa == null
        ? const <Inquilino>[]
        : await ref.read(speseCreateInquiliniProvider(casa.id).future);
    final result = await controller.submit(
      casa: casa,
      inquilini: inquilini,
      currentUser: ref.read(authViewModelProvider).valueOrNull,
    );
    if (result == null || !mounted) return;

    final form = ref.read(speseCreateFormProvider);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _SpesaAggiuntaDialog(
        descrizione: result.spesa.descrizione,
        importo: result.importo,
        nPartecipanti: result.numeroPartecipanti,
        haAnticipato: form.hoAnticipatoPerTutti,
        anticipatoreNome: result.anticipatoreNome,
        onTornaAlleSpese: () {
          Navigator.of(dialogCtx).pop();
          navigator.pushNamedAndRemoveUntil(
            ListaSpeseAdminScreen.routeName,
            (_) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.of(context);
    final form = ref.watch(speseCreateFormProvider);
    final controller = ref.watch(speseCreateFormProvider.notifier);
    final currentUser = ref.watch(authViewModelProvider).valueOrNull;
    final casaAsync = ref.watch(
      speseCreateCasaProvider(activeCasaController.selectedCasaId),
    );
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(speseCreateInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (e, s) => AsyncValue<List<Inquilino>>.error(e, s),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nuova Spesa',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.brandPrimary,
              fontSize: AppSizes.p23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p10),
          // Importo card con display grande
          _ImportoCard(
            value: form.importo,
            hasError: form.showErrors && !form.hasValidImporto,
            onChanged: controller.setImporto,
          ),
          const SizedBox(height: AppSizes.p8),
          _PopupDescrizioneField(
            controller: _descrizioneController,
            onChanged: controller.setDescrizione,
          ),
          const SizedBox(height: AppSizes.p18),
          inquiliniAsync.when(
            loading: () => const _DivisioneLoading(),
            error: (_, _) => _PopupDivisioneSection(
              inquilini: const [],
              selectedIds: form.selectedInquiliniIds,
              currentUserId: null,
              importo: form.importo,
              showError: form.showErrors && form.selectedInquiliniIds.isEmpty,
              onSelected: controller.toggleInquilino,
            ),
            data: (inquilini) {
              final currentUserId = resolveCurrentUserId(
                inquilini,
                currentUser,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                controller.prepopulateInquilini(inquilini, currentUserId);
              });
              return _PopupDivisioneSection(
                inquilini: inquilini,
                selectedIds: form.selectedInquiliniIds,
                currentUserId: currentUserId,
                importo: form.importo,
                showError: form.showErrors && form.selectedInquiliniIds.isEmpty,
                onSelected: controller.toggleInquilino,
              );
            },
          ),
          const SizedBox(height: AppSizes.p8),
          _PopupPaidForAllRow(
            value: form.hoAnticipatoPerTutti,
            onChanged: controller.setHoAnticipatoPerTutti,
          ),
          if (form.showMissingError) ...[
            const SizedBox(height: AppSizes.p10),
            _ErrorLine(message: 'Dati mancanti: compila i campi necessari'),
          ],
          const SizedBox(height: AppSizes.p14),
          FabSaveButton(
            label: 'Salva spesa',
            onPressed: form.canSubmit ? _submit : null,
            isLoading: form.isSubmitting,
          ),
          const SizedBox(height: AppSizes.p8),
          AppCancelButton(
            onPressed: form.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _PopupDescrizioneField extends StatelessWidget {
  const _PopupDescrizioneField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.screenTitleStrong.copyWith(
        color: AppColors.textOnDark,
        fontSize: AppSizes.p14,
      ),
      decoration: InputDecoration(
        hintText: 'Descrizione spesa...',
        hintStyle: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.55),
          fontSize: AppSizes.p14,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide.none,
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
          vertical: AppSizes.p10,
        ),
      ),
    );
  }
}

class _PopupDivisioneSection extends StatelessWidget {
  const _PopupDivisioneSection({
    required this.inquilini,
    required this.selectedIds,
    required this.currentUserId,
    required this.importo,
    required this.showError,
    required this.onSelected,
  });

  final List<Inquilino> inquilini;
  final Set<String> selectedIds;
  final String? currentUserId;
  final String importo;
  final bool showError;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedIds.length;
    final importoNum = double.tryParse(importo.replaceAll(',', '.')) ?? 0;
    final quota = selectedCount > 0 ? importoNum / selectedCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DIVIDI TRA',
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.brandPrimaryDark,
            fontSize: AppSizes.p13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.p6),
        ...inquilini.map((inq) {
          final isSelected = selectedIds.contains(inq.id);
          final isCurrentUser = inq.id == currentUserId;
          final quotaLabel = isSelected && quota > 0
              ? '€ ${quota.toStringAsFixed(2).replaceAll('.', ',')}'
              : '–';
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p2),
            child: _PopupInquilinoCheckbox(
              inquilino: inq,
              isSelected: isSelected,
              isCurrentUser: isCurrentUser,
              quotaLabel: quotaLabel,
              onChanged: () => onSelected(inq.id),
            ),
          );
        }),
        if (showError) ...[
          const SizedBox(height: AppSizes.p8),
          const _ErrorLine(message: 'Seleziona almeno un coinquilino'),
        ],
      ],
    );
  }
}

class _PopupInquilinoCheckbox extends StatelessWidget {
  const _PopupInquilinoCheckbox({
    required this.inquilino,
    required this.isSelected,
    required this.isCurrentUser,
    required this.quotaLabel,
    required this.onChanged,
  });

  final Inquilino inquilino;
  final bool isSelected;
  final bool isCurrentUser;
  final String quotaLabel;
  final VoidCallback onChanged;

  Color _avatarColor(String id) => userAvatarColorsForSeed(id).background;

  @override
  Widget build(BuildContext context) {
    final name = inquilino.username.isNotEmpty
        ? inquilino.username
        : inquilino.email.split('@').first;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isCurrentUser ? null : onChanged,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p4,
            vertical: AppSizes.p3,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _avatarColor(inquilino.id),
                radius: 19,
                child: Text(
                  resolveUserInitials(displayName: name, fallback: '?'),
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.p13,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  isCurrentUser ? '$name (Tu)' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: const Color(
                      0xFF7A7490,
                    ).withValues(alpha: isCurrentUser ? 0.5 : 1.0),
                    fontSize: AppSizes.p13,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isSelected,
                  onChanged: isCurrentUser ? null : (_) => onChanged(),
                  activeColor: AppColors.brandAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                quotaLabel,
                textAlign: TextAlign.right,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: isSelected
                      ? AppColors.brandAccent
                      : AppColors.textOnDark.withValues(alpha: 0.3),
                  fontSize: AppSizes.p12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopupPaidForAllRow extends StatelessWidget {
  const _PopupPaidForAllRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ho anticipato per tutti',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.dividerDark,
                    fontSize: AppSizes.p16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Gli altri vedranno il debito verso di te',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.textMutedDark,
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

class _ImportoCard extends StatefulWidget {
  const _ImportoCard({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  final String value;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  State<_ImportoCard> createState() => _ImportoCardState();
}

class _ImportoCardState extends State<_ImportoCard> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _focus = FocusNode();
    _focus.addListener(() {
      if (mounted) {
        setState(() => _hasFocus = _focus.hasFocus);
      }
    });
  }

  @override
  void didUpdateWidget(_ImportoCard old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p14,
          AppSizes.p10,
          AppSizes.p14,
          AppSizes.p10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: widget.hasError
                ? AppColors.statusNegative
                : _hasFocus
                ? AppColors.brandAccent
                : AppColors.transparent,
            width: _hasFocus ? 2 : 1.5,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.brandAccent.withValues(alpha: 0.22),
                    blurRadius: AppSizes.p14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: _hasFocus
                    ? AppColors.brandAccent
                    : AppColors.textOnDark.withValues(alpha: 0.55),
                fontSize: _hasFocus ? 13 : 12,
                fontWeight: FontWeight.w700,
              ),
              child: Text('Importo'),
            ),
            const SizedBox(height: AppSizes.p4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(13)],
                    textAlign: TextAlign.right,
                    cursorColor: AppColors.brandAccent,
                    onChanged: widget.onChanged,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.brandAccent,
                      fontSize: AppSizes.p28,
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
                        fontSize: AppSizes.p28,
                        fontWeight: FontWeight.w800,
                      ),
                      hintStyle: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.brandAccent.withValues(alpha: 0.34),
                        fontSize: AppSizes.p28,
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
// UI — Descrizione field
// ---------------------------------------------------------------------------

class _DescrizioneField extends StatefulWidget {
  const _DescrizioneField({
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  final String value;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  State<_DescrizioneField> createState() => _DescrizioneFieldState();
}

class _DescrizioneFieldState extends State<_DescrizioneField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_DescrizioneField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: AppTextStyles.screenTitleStrong.copyWith(
        color: AppColors.textOnDark,
        fontSize: AppSizes.p14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Descrizione spesa',
        hintStyle: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.45),
          fontSize: AppSizes.p14,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: widget.hasError
                ? AppColors.statusNegative
                : AppColors.transparent,
            width: AppSizes.p1_5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: widget.hasError
                ? AppColors.statusNegative
                : AppColors.transparent,
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
// UI — Divisione section
// ---------------------------------------------------------------------------

class _DivisioneLoading extends StatelessWidget {
  const _DivisioneLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AppSizes.p120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ---------------------------------------------------------------------------
// UI — Error line
// ---------------------------------------------------------------------------

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

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
// Confirmation banner dialog
// ---------------------------------------------------------------------------

class _SpesaAggiuntaDialog extends StatelessWidget {
  const _SpesaAggiuntaDialog({
    required this.descrizione,
    required this.importo,
    required this.nPartecipanti,
    required this.haAnticipato,
    required this.anticipatoreNome,
    required this.onTornaAlleSpese,
  });

  final String descrizione;
  final double importo;
  final int nPartecipanti;
  final bool haAnticipato;
  final String anticipatoreNome;
  final VoidCallback onTornaAlleSpese;

  String _fmt(double v) => '€ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final quota = nPartecipanti > 0 ? importo / nPartecipanti : importo;

    return Dialog(
      backgroundColor: AppColors.surfaceDarkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius20),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p32,
        vertical: AppSizes.p48,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p24,
          AppSizes.p32,
          AppSizes.p24,
          AppSizes.p28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark
            Container(
              width: AppSizes.p72,
              height: AppSizes.p72,
              decoration: const BoxDecoration(
                color: AppColors.surfaceDarkCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successBright,
                size: AppSizes.p72,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            Text(
              'Spesa aggiunta!',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              'La spesa "$descrizione" è stata aggiunta. I coinquilini sono stati notificati',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.65),
                fontSize: AppSizes.p14,
                height: AppSizes.p1_4,
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            // Summary card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkElevated,
                borderRadius: BorderRadius.circular(AppSizes.radius12),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Totale', value: _fmt(importo)),
                  const Divider(
                    height: AppSizes.p1,
                    color: AppColors.surfaceDarkMuted,
                  ),
                  _SummaryRow(label: 'Quota per persona', value: _fmt(quota)),
                  if (haAnticipato) ...[
                    const Divider(
                      height: AppSizes.p1,
                      color: AppColors.surfaceDarkMuted,
                    ),
                    _SummaryRow(
                      label: 'Ha pagato',
                      value: anticipatoreNome.isNotEmpty
                          ? anticipatoreNome
                          : 'Tu',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            SizedBox(
              width: double.infinity,
              child: MainCtaButton(
                label: 'Torna alle spese',
                onPressed: onTornaAlleSpese,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textOnDark.withValues(alpha: 0.7),
              fontSize: AppSizes.p15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
