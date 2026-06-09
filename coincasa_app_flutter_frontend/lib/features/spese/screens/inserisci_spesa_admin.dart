import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/features/spese/screens/modifica_spesa_admin.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final speseCreateCasaProvider = FutureProvider.family<Casa?, String?>((
  ref,
  selectedCasaId,
) async {
  final caseUtente = await ApiProvider.casa.list();
  if (caseUtente.isEmpty) return null;
  if (selectedCasaId != null && selectedCasaId.isNotEmpty) {
    for (final casa in caseUtente) {
      if (casa.id == selectedCasaId) return casa;
    }
  }
  return caseUtente.first;
});

final speseCreateInquiliniProvider =
    FutureProvider.family<List<Inquilino>, String?>((ref, casaId) {
      if (casaId == null || casaId.isEmpty) return const [];
      return ApiProvider.casa.listInquilini(casaId);
    });

final speseCreateFormProvider =
    StateNotifierProvider.autoDispose<
      _SpesaCreateFormController,
      _SpesaCreateFormState
    >((ref) => _SpesaCreateFormController());

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
    final form = ref.read(speseCreateFormProvider);
    final activeCasaController = ActiveCasaScope.of(context);
    final casa = await ref.read(
      speseCreateCasaProvider(activeCasaController.selectedCasaId).future,
    );
    if (!controller.validateBeforeSubmit()) return;
    if (casa == null || casa.id.isEmpty) {
      controller.setSubmitError('Nessuna casa disponibile.');
      return;
    }
    controller.setSubmitting(true);
    try {
      final inquilini = await ref.read(
        speseCreateInquiliniProvider(casa.id).future,
      );
      final currentUserId = _resolveCurrentUserId(inquilini);
      final partecipanti = _buildPartecipantiIds(
        selectedIds: form.selectedInquiliniIds,
        currentUserId: currentUserId,
      );
      final payload = <String, dynamic>{
        'descrizione': form.descrizione.trim(),
        'importo': double.parse(form.importo.replaceAll(',', '.')),
        'partecipanti': partecipanti,
        'dataSpesa': _fmtDate(form.dataSpesa),
        'isRicorrente': form.spesaRicorrente,
        if (form.hoAnticipatoPerTutti && currentUserId != null)
          'anticipataDa': currentUserId,
        if (form.spesaRicorrente) ...{
          'dataScadenza': _fmtDate(form.dataSpesa),
          'cadenzaGiorni': _cadenzaGiorniFor(form.frequenza),
        },
      };
      await ApiProvider.spese.create(casa.id, payload);
      if (!mounted) return;
      final currentUserName = ApiProvider.client.currentUserName ?? '';
      final importoNum = double.parse(form.importo.replaceAll(',', '.'));
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => _SpesaAggiuntaDialog(
          descrizione: form.descrizione.trim(),
          importo: importoNum,
          nPartecipanti: partecipanti.length,
          haAnticipato: form.hoAnticipatoPerTutti,
          anticipatoreNome: currentUserName.split(' ').first,
          onTornaAlleSpese: () {
            Navigator.of(dialogCtx).pop();
            Navigator.of(context).pushNamedAndRemoveUntil(
              ListaSpeseAdminScreen.routeName,
              (_) => false,
            );
          },
        ),
      );
    } catch (_) {
      controller.setSubmitError('Impossibile salvare la spesa. Riprova.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.of(context);
    final form = ref.watch(speseCreateFormProvider);
    final controller = ref.read(speseCreateFormProvider.notifier);
    final casaAsync = ref.watch(
      speseCreateCasaProvider(activeCasaController.selectedCasaId),
    );
    final isAdmin = casaAsync.maybeWhen(
      data: (casa) =>
          casa?.ruolo == 'HomeAdmin' || casa?.ruolo == 'SysAdmin',
      orElse: () => false,
    );
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(speseCreateInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (e, s) => AsyncValue<List<Inquilino>>.error(e, s),
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Spese',
                            style: AppTextStyles.screenTitleStrong.copyWith(
                              color: AppColors.brandAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Importo — shared widget
                    SpesaFormImportoCard(
                      controller: _importoCtrl,
                      hasError: form.showErrors && !form.hasValidImporto,
                      onChanged: controller.setImporto,
                    ),
                    const SizedBox(height: 10),

                    // Data + Descrizione — shared widgets
                    Row(
                      children: [
                        SpesaFormDateField(
                          value: form.dataSpesa,
                          onChanged: controller.setDataSpesa,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SpesaFormDescrizioneField(
                            controller: _descCtrl,
                            hasError: form.showErrors &&
                                form.descrizione.trim().isEmpty,
                            onChanged: controller.setDescrizione,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Dividi tra — shared widget
                    inquiliniAsync.when(
                      loading: () => const SpesaFormDivisioneLoading(),
                      error: (_, _) => SpesaFormDivisioneSection(
                        inquilini: const [],
                        selectedIds: form.selectedInquiliniIds,
                        lockedId: form.currentUserId,
                        importo: form.importo,
                        showError: form.showErrors &&
                            form.selectedInquiliniIds.isEmpty,
                        onSelected: controller.toggleInquilino,
                      ),
                      data: (inquilini) {
                        final currentUserId = _resolveCurrentUserId(inquilini);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          controller.ensureSelected(currentUserId);
                        });
                        return SpesaFormDivisioneSection(
                          inquilini: inquilini,
                          selectedIds: form.selectedInquiliniIds,
                          lockedId: currentUserId,
                          importo: form.importo,
                          showError: form.showErrors &&
                              form.selectedInquiliniIds.isEmpty,
                          onSelected: controller.toggleInquilino,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Toggle panel — shared widgets
                    SpesaFormTogglePanel(
                      children: [
                        SpesaFormPaidForAllRow(
                          value: form.hoAnticipatoPerTutti,
                          onChanged: controller.setHoAnticipatoPerTutti,
                        ),
                        const Divider(height: 1, color: Color(0xFF3A3555)),
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
                        onChanged: controller.setFrequenza,
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

            // CTA pinned — shared widget
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: SpesaFormConfermaButton(
                label: 'Conferma e aggiungi',
                enabled: form.canSubmit,
                submitting: form.isSubmitting,
                onPressed: _submit,
              ),
            ),
          ],
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
  final _importoController = TextEditingController();
  final _descrizioneController = TextEditingController();

  @override
  void dispose() {
    _importoController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final controller = ref.read(speseCreateFormProvider.notifier);
    final form = ref.read(speseCreateFormProvider);
    final navigator = Navigator.of(context);
    final activeCasaController = ActiveCasaScope.of(context);
    final casa = await ref.read(
      speseCreateCasaProvider(activeCasaController.selectedCasaId).future,
    );
    if (!controller.validateBeforeSubmit()) return;
    if (casa == null || casa.id.isEmpty) {
      controller.setSubmitError('Nessuna casa disponibile.');
      return;
    }
    controller.setSubmitting(true);
    try {
      final inquilini = await ref.read(
        speseCreateInquiliniProvider(casa.id).future,
      );
      final currentUserId = _resolveCurrentUserId(inquilini);
      final partecipanti = _buildPartecipantiIds(
        selectedIds: form.selectedInquiliniIds,
        currentUserId: currentUserId,
      );
      final payload = <String, dynamic>{
        'descrizione': form.descrizione.trim(),
        'importo': double.parse(form.importo.replaceAll(',', '.')),
        'partecipanti': partecipanti,
        'dataSpesa': _fmtDate(form.dataSpesa),
        'isRicorrente': form.spesaRicorrente,
        if (form.hoAnticipatoPerTutti && currentUserId != null)
          'anticipataDa': currentUserId,
        if (form.spesaRicorrente) ...{
          'dataScadenza': _fmtDate(form.dataSpesa),
          'cadenzaGiorni': _cadenzaGiorniFor(form.frequenza),
        },
      };
      await ApiProvider.spese.create(casa.id, payload);
      if (!mounted) return;
      final currentUserName = ApiProvider.client.currentUserName ?? '';
      final importoNum = double.parse(form.importo.replaceAll(',', '.'));
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => _SpesaAggiuntaDialog(
          descrizione: form.descrizione.trim(),
          importo: importoNum,
          nPartecipanti: partecipanti.length,
          haAnticipato: form.hoAnticipatoPerTutti,
          anticipatoreNome: currentUserName.split(' ').first,
          onTornaAlleSpese: () {
            Navigator.of(dialogCtx).pop();
            navigator.pushNamedAndRemoveUntil(
              ListaSpeseAdminScreen.routeName,
              (_) => false,
            );
          },
        ),
      );
    } catch (_) {
      controller.setSubmitError('Impossibile salvare la spesa. Riprova.');
    } finally {
      if (mounted) controller.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.of(context);
    final form = ref.watch(speseCreateFormProvider);
    final controller = ref.read(speseCreateFormProvider.notifier);
    final casaAsync = ref.watch(
      speseCreateCasaProvider(activeCasaController.selectedCasaId),
    );
    final isAdmin = casaAsync.maybeWhen(
      data: (casa) =>
          casa?.ruolo == 'HomeAdmin' || casa?.ruolo == 'SysAdmin',
      orElse: () => false,
    );
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(speseCreateInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (e, s) => AsyncValue<List<Inquilino>>.error(e, s),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nuova Spesa',
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.brandPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _PopupImportoField(
          controller: _importoController,
          hasError: form.showErrors && !form.hasValidImporto,
          onChanged: controller.setImporto,
        ),
        const SizedBox(height: 8),
        _PopupDescrizioneField(
          controller: _descrizioneController,
          onChanged: controller.setDescrizione,
        ),
        const SizedBox(height: 20),
        inquiliniAsync.when(
          loading: () => const _DivisioneLoading(),
          error: (_, _) => _PopupDivisioneSection(
            inquilini: const [],
            selectedIds: form.selectedInquiliniIds,
            currentUserId: null,
            showError: form.showErrors && form.selectedInquiliniIds.isEmpty,
            onSelected: controller.toggleInquilino,
          ),
          data: (inquilini) {
            final currentUserId = _resolveCurrentUserId(inquilini);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              controller.ensureSelected(currentUserId);
            });
            return _PopupDivisioneSection(
              inquilini: inquilini,
              selectedIds: form.selectedInquiliniIds,
              currentUserId: currentUserId,
              showError: form.showErrors && form.selectedInquiliniIds.isEmpty,
              onSelected: controller.toggleInquilino,
            );
          },
        ),
        const SizedBox(height: 12),
        _PopupPaidForAllRow(
          value: form.hoAnticipatoPerTutti,
          onChanged: controller.setHoAnticipatoPerTutti,
        ),
        const SizedBox(height: 12),
        _PopupRecurringRow(
          value: form.spesaRicorrente,
          isAdmin: isAdmin,
          onChanged: isAdmin ? controller.setSpesaRicorrente : null,
        ),
        if (isAdmin && form.spesaRicorrente) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Frequenza',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.brandPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FrequencyDropdown(
              value: form.frequenza,
              onChanged: controller.setFrequenza,
            ),
          ),
        ],
        if (form.showMissingError) ...[
          const SizedBox(height: 14),
          _ErrorLine(message: 'Dati mancanti: compila i campi necessari'),
        ],
        const SizedBox(height: 16),
        _PopupSaveButton(
          enabled: form.canSubmit,
          submitting: form.isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _CancelButton(
            enabled: !form.isSubmitting,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Popup-specific widgets (stile originale)
// ---------------------------------------------------------------------------

class _PopupImportoField extends StatelessWidget {
  const _PopupImportoField({
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppTextStyles.screenTitleStrong.copyWith(
        color: AppColors.textOnDark,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Importo...',
        hintStyle: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.72),
          fontSize: 16,
        ),
        prefixText: '€ ',
        prefixStyle: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark,
          fontSize: 16,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: hasError ? AppColors.statusNegative : Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: hasError ? AppColors.statusNegative : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: const BorderSide(color: AppColors.brandAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p12,
        ),
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
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Descrizione spesa...',
        hintStyle: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.72),
          fontSize: 16,
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
          borderSide: const BorderSide(color: AppColors.brandAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p12,
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
    required this.showError,
    required this.onSelected,
  });

  final List<Inquilino> inquilini;
  final Set<String> selectedIds;
  final String? currentUserId;
  final bool showError;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            'DIVIDI TRA',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: const Color(0xFF5228AD),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...inquilini.map((inq) {
          final isSelected = selectedIds.contains(inq.id);
          final isCurrentUser = inq.id == currentUserId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PopupInquilinoCheckbox(
              inquilino: inq,
              isSelected: isSelected,
              isCurrentUser: isCurrentUser,
              onChanged: () => onSelected(inq.id),
            ),
          );
        }),
        if (showError) ...[
          const SizedBox(height: 12),
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
    required this.onChanged,
  });

  final Inquilino inquilino;
  final bool isSelected;
  final bool isCurrentUser;
  final VoidCallback onChanged;

  Color _avatarColor(String id) {
    const colors = [
      Color(0xFF1B5E20),
      Color(0xFFE53935),
      Color(0xFF6D4C41),
      Color(0xFF1565C0),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(
          color: isSelected ? AppColors.brandAccent : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCurrentUser ? null : onChanged,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _avatarColor(inquilino.id),
                  radius: 18,
                  child: Text(
                    resolveUserInitials(
                      displayName: inquilino.nomeCompleto,
                      email: inquilino.email,
                      fallback: '?',
                    ),
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isCurrentUser
                        ? '${inquilino.nome} (Tu)'
                        : inquilino.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: isCurrentUser
                          ? AppColors.textOnDark.withValues(alpha: 0.45)
                          : AppColors.textOnDark,
                      fontSize: 14,
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: isCurrentUser ? null : (_) => onChanged(),
                  activeColor: AppColors.brandAccent,
                ),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ho anticipato per tutti',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: const Color(0xFF3B3150),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Gli altri vedranno il debito verso di te',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: const Color(0xFF645A76),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.brandAccent,
          ),
        ],
      ),
    );
  }
}

class _PopupRecurringRow extends StatelessWidget {
  const _PopupRecurringRow({
    required this.value,
    required this.isAdmin,
    required this.onChanged,
  });

  final bool value;
  final bool isAdmin;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spesa ricorrente',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: const Color(0xFF3B3150),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ripete seguendo la data precedente',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: const Color(0xFF645A76),
                    fontSize: 12,
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
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.textOnDark,
            activeTrackColor: AppColors.brandPrimary,
          ),
        ],
      ),
    );
  }
}

class _PopupSaveButton extends StatelessWidget {
  const _PopupSaveButton({
    required this.enabled,
    required this.submitting,
    required this.onPressed,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled && !submitting ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            submitting ? AppColors.textMuted : const Color(0xFFA48DDA),
        disabledBackgroundColor: AppColors.textMuted,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(
        submitting ? 'Salvataggio...' : 'Aggiungi spesa',
        style: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark,
          fontSize: 22,
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
        backgroundColor: AppColors.errorContainerStrong,
        foregroundColor: AppColors.errorStrong,
        side: const BorderSide(color: AppColors.errorStrong, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        disabledForegroundColor: AppColors.textMuted.withValues(alpha: 0.42),
      ),
      child: Text(
        'Annulla',
        style: AppTextStyles.buttonCompact.copyWith(
          color: AppColors.errorStrong,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form State
// ---------------------------------------------------------------------------

class _SpesaCreateFormState {
  _SpesaCreateFormState({
    this.importo = '',
    this.descrizione = '',
    this.selectedInquiliniIds = const {},
    this.currentUserId,
    this.dataSpesa,
    this.hoAnticipatoPerTutti = false,
    this.spesaRicorrente = false,
    this.frequenza = 'Mensile',
    this.showErrors = false,
    this.isSubmitting = false,
    this.submitError = '',
  });

  final String importo;
  final String descrizione;
  final Set<String> selectedInquiliniIds;
  final String? currentUserId;
  final DateTime? dataSpesa;
  final bool hoAnticipatoPerTutti;
  final bool spesaRicorrente;
  final String frequenza;
  final bool showErrors;
  final bool isSubmitting;
  final String submitError;

  DateTime get effectiveDate => dataSpesa ?? DateTime.now();

  bool get hasValidImporto =>
      importo.trim().isNotEmpty &&
      (double.tryParse(importo.trim().replaceAll(',', '.')) ?? 0) > 0;

  bool get canSubmit =>
      hasValidImporto &&
      descrizione.trim().isNotEmpty &&
      selectedInquiliniIds.isNotEmpty &&
      !isSubmitting;

  bool get showMissingError => submitError.isNotEmpty && showErrors;

  _SpesaCreateFormState copyWith({
    String? importo,
    String? descrizione,
    Set<String>? selectedInquiliniIds,
    String? currentUserId,
    DateTime? dataSpesa,
    bool? hoAnticipatoPerTutti,
    bool? spesaRicorrente,
    String? frequenza,
    bool? showErrors,
    bool? isSubmitting,
    String? submitError,
  }) {
    return _SpesaCreateFormState(
      importo: importo ?? this.importo,
      descrizione: descrizione ?? this.descrizione,
      selectedInquiliniIds: selectedInquiliniIds ?? this.selectedInquiliniIds,
      currentUserId: currentUserId ?? this.currentUserId,
      dataSpesa: dataSpesa ?? this.dataSpesa,
      hoAnticipatoPerTutti: hoAnticipatoPerTutti ?? this.hoAnticipatoPerTutti,
      spesaRicorrente: spesaRicorrente ?? this.spesaRicorrente,
      frequenza: frequenza ?? this.frequenza,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError ?? this.submitError,
    );
  }
}

// ---------------------------------------------------------------------------
// Form Controller
// ---------------------------------------------------------------------------

class _SpesaCreateFormController
    extends StateNotifier<_SpesaCreateFormState> {
  _SpesaCreateFormController() : super(_SpesaCreateFormState());

  void setImporto(String v) => state = state.copyWith(importo: v, submitError: '');
  void setDescrizione(String v) => state = state.copyWith(descrizione: v, submitError: '');
  void setDataSpesa(DateTime v) => state = state.copyWith(dataSpesa: v);
  void setHoAnticipatoPerTutti(bool v) =>
      state = state.copyWith(hoAnticipatoPerTutti: v);
  void setSpesaRicorrente(bool v) =>
      state = state.copyWith(spesaRicorrente: v);
  void setFrequenza(String v) => state = state.copyWith(frequenza: v);

  void toggleInquilino(String id) {
    // L'utente corrente non può essere rimosso
    if (id == state.currentUserId) return;
    final ids = {...state.selectedInquiliniIds};
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(selectedInquiliniIds: ids, submitError: '');
  }

  void ensureSelected(String? id) {
    if (id == null || id.isEmpty) return;
    if (state.selectedInquiliniIds.contains(id) &&
        state.currentUserId == id) {
      return;
    }
    state = state.copyWith(
      selectedInquiliniIds: {...state.selectedInquiliniIds, id},
      currentUserId: id,
    );
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
  void setSubmitError(String e) =>
      state = state.copyWith(submitError: e, showErrors: true, isSubmitting: false);
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

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(_ImportoCard old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _displayAmount {
    final raw = widget.value.trim().replaceAll(',', '.');
    final n = double.tryParse(raw);
    if (n == null || n == 0) return '€ 0,00';
    return '€ ${n.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: widget.hasError
                ? AppColors.statusNegative
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Importo',
              style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.55),
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _displayAmount,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.brandPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                // TextField invisibile per catturare l'input
                SizedBox(
                  width: 0,
                  height: 0,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: widget.onChanged,
                    style: const TextStyle(fontSize: 1, color: Colors.transparent),
                    decoration: const InputDecoration(border: InputBorder.none),
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
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
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
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Descrizione spesa',
        hintStyle: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark.withValues(alpha: 0.45),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: widget.hasError
                ? AppColors.statusNegative
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide: BorderSide(
            color: widget.hasError
                ? AppColors.statusNegative
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          borderSide:
              const BorderSide(color: AppColors.brandAccent, width: 2),
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
// UI — Divisione section
// ---------------------------------------------------------------------------

class _DivisioneLoading extends StatelessWidget {
  const _DivisioneLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ---------------------------------------------------------------------------
// UI — Frequenza dropdown
// ---------------------------------------------------------------------------

class _FrequencyDropdown extends StatelessWidget {
  const _FrequencyDropdown({
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
// UI — Error line
// ---------------------------------------------------------------------------

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.warning_rounded,
            color: AppColors.statusNegative, size: 18),
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

  String _fmt(double v) =>
      '€ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final quota = nPartecipanti > 0 ? importo / nPartecipanti : importo;

    return Dialog(
      backgroundColor: const Color(0xFF1E1A2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1A2D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4CAF50),
                size: 72,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Spesa aggiunta!',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.textOnDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La spesa "$descrizione" è stata aggiunta. I coinquilini sono stati notificati',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.65),
                fontSize: 14,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Summary card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Totale', value: _fmt(importo)),
                  const Divider(height: 1, color: Color(0xFF2E2A42)),
                  _SummaryRow(
                    label: 'Quota per persona',
                    value: _fmt(quota),
                  ),
                  if (haAnticipato) ...[
                    const Divider(height: 1, color: Color(0xFF2E2A42)),
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
            const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textOnDark.withValues(alpha: 0.7),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.textOnDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
  for (final inquilino in inquilini) {
    final values = [
      inquilino.email,
      inquilino.username,
      inquilino.nome,
      inquilino.nomeCompleto,
    ].map((v) => v.trim().toLowerCase());
    if ((email != null && values.contains(email)) ||
        (name != null && values.contains(name))) {
      return inquilino.id;
    }
  }
  return inquilini.isNotEmpty ? inquilini.first.id : null;
}

List<String> _buildPartecipantiIds({
  required Set<String> selectedIds,
  required String? currentUserId,
}) {
  final set = <String>{...selectedIds};
  if (currentUserId != null && currentUserId.isNotEmpty) set.add(currentUserId);
  return set.toList();
}

int _cadenzaGiorniFor(String frequenza) => switch (frequenza) {
  'Bimestrale' => 60,
  'Trimestrale' => 90,
  'Annuale' => 365,
  _ => 30,
};

String _fmtDate(DateTime? d) =>
    (d ?? DateTime.now()).toIso8601String().split('T').first;
