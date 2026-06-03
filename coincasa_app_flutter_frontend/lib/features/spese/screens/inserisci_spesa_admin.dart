import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_admin.dart';

final speseCreateCasaProvider = FutureProvider.autoDispose
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

final speseCreateInquiliniProvider = FutureProvider.autoDispose
    .family<List<Inquilino>, String?>((ref, casaId) {
      if (casaId == null || casaId.isEmpty) {
        return const [];
      }
      return ApiProvider.casa.listInquilini(casaId);
    });

final speseCreateFormProvider =
    StateNotifierProvider.autoDispose<
      _SpesaCreateFormController,
      _SpesaCreateFormState
    >((ref) => _SpesaCreateFormController());

class InserisciSpesaScreen extends ConsumerStatefulWidget {
  const InserisciSpesaScreen({super.key});

  static const String routeName = '/spese/nuovo';

  @override
  ConsumerState<InserisciSpesaScreen> createState() =>
      _InserisciSpesaScreenState();
}

class _InserisciSpesaScreenState extends ConsumerState<InserisciSpesaScreen> {
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
    final activeCasaController = ActiveCasaScope.of(context);
    final casa = await ref.read(
      speseCreateCasaProvider(activeCasaController.selectedCasaId).future,
    );

    if (!controller.validateBeforeSubmit()) {
      return;
    }
    if (casa == null || casa.id.isEmpty) {
      controller.setSubmitError('Nessuna casa disponibile.');
      return;
    }

    controller.setSubmitting(true);
    try {
      final normalizedImporto = form.importo.replaceAll(',', '.');
      final nuovaSpesa = await ApiProvider.spese.create(casa.id, {
        'descrizione': form.descrizione.trim(),
        'importo': double.parse(normalizedImporto),
        'data': DateTime.now().toIso8601String(),
        'partecipanti': form.selectedInquiliniIds.toList(),
        'hoAnticipatoPerTutti': form.hoAnticipatoPerTutti,
        'isRicorrente': form.spesaRicorrente,
        if (form.spesaRicorrente) 'frequenza': form.frequenza,
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        DettaglioSpesaAdminScreen.routeName,
        arguments: nuovaSpesa.id,
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
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(speseCreateInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (error, stackTrace) =>
          AsyncValue<List<Inquilino>>.error(error, stackTrace),
    );

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
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
                  'Inserisci spesa',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 17),
                _ImportoField(
                  controller: _importoController,
                  hasError: form.showErrors && form.importo.isEmpty,
                  onChanged: controller.setImporto,
                ),
                const SizedBox(height: 12),
                _DescrizioneField(
                  controller: _descrizioneController,
                  onChanged: controller.setDescrizione,
                ),
                const SizedBox(height: 25),
                inquiliniAsync.when(
                  loading: () => const _DivisioneLoading(),
                  error: (_, _) => _DivisioneSection(
                    inquilini: const [],
                    selectedIds: form.selectedInquiliniIds,
                    showError:
                        form.showErrors && form.selectedInquiliniIds.isEmpty,
                    onSelected: controller.toggleInquilino,
                  ),
                  data: (inquilini) => _DivisioneSection(
                    inquilini: inquilini,
                    selectedIds: form.selectedInquiliniIds,
                    showError:
                        form.showErrors && form.selectedInquiliniIds.isEmpty,
                    onSelected: controller.toggleInquilino,
                  ),
                ),
                const SizedBox(height: 20),
                _PaidForAllRow(
                  value: form.hoAnticipatoPerTutti,
                  onChanged: controller.setHoAnticipatoPerTutti,
                ),
                const SizedBox(height: 12),
                _RecurringRow(
                  value: form.spesaRicorrente,
                  onChanged: controller.setSpesaRicorrente,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Frequenza',
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: form.spesaRicorrente
                          ? AppColors.brandPrimary
                          : const Color(0xFF6A5A86),
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
                    enabled: form.spesaRicorrente,
                    onChanged: controller.setFrequenza,
                  ),
                ),
                if (form.showMissingError) ...[
                  const SizedBox(height: 24),
                  const _ErrorLine(
                    message: 'Dati mancanti: compila i campi necessari',
                  ),
                ],
                SizedBox(height: form.showMissingError ? 20 : 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SaveButton(
                    enabled: form.canSubmit,
                    submitting: form.isSubmitting,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
}

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

    if (!controller.validateBeforeSubmit()) {
      return;
    }
    if (casa == null || casa.id.isEmpty) {
      controller.setSubmitError('Nessuna casa disponibile.');
      return;
    }

    controller.setSubmitting(true);
    try {
      final normalizedImporto = form.importo.replaceAll(',', '.');
      final nuovaSpesa = await ApiProvider.spese.create(casa.id, {
        'descrizione': form.descrizione.trim(),
        'importo': double.parse(normalizedImporto),
        'data': DateTime.now().toIso8601String(),
        'partecipanti': form.selectedInquiliniIds.toList(),
        'hoAnticipatoPerTutti': form.hoAnticipatoPerTutti,
        'isRicorrente': form.spesaRicorrente,
        if (form.spesaRicorrente) 'frequenza': form.frequenza,
      });

      if (!mounted) {
        return;
      }
      navigator.pop();
      navigator.pushNamed(
        DettaglioSpesaAdminScreen.routeName,
        arguments: nuovaSpesa.id,
      );
    } catch (_) {
      controller.setSubmitError('Impossibile salvare la spesa. Riprova.');
    } finally {
      if (mounted) {
        controller.setSubmitting(false);
      }
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
    final inquiliniAsync = casaAsync.when(
      data: (casa) => ref.watch(speseCreateInquiliniProvider(casa?.id)),
      loading: () => const AsyncValue<List<Inquilino>>.loading(),
      error: (error, stackTrace) =>
          AsyncValue<List<Inquilino>>.error(error, stackTrace),
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
        _ImportoField(
          controller: _importoController,
          hasError: form.showErrors && form.importo.isEmpty,
          onChanged: controller.setImporto,
        ),
        const SizedBox(height: 8),
        _DescrizioneField(
          controller: _descrizioneController,
          onChanged: controller.setDescrizione,
        ),
        const SizedBox(height: 20),
        inquiliniAsync.when(
          loading: () => const _DivisioneLoading(),
          error: (_, _) => _DivisioneSection(
            inquilini: const [],
            selectedIds: form.selectedInquiliniIds,
            showError: form.showErrors && form.selectedInquiliniIds.isEmpty,
            onSelected: controller.toggleInquilino,
          ),
          data: (inquilini) => _DivisioneSection(
            inquilini: inquilini,
            selectedIds: form.selectedInquiliniIds,
            showError: form.showErrors && form.selectedInquiliniIds.isEmpty,
            onSelected: controller.toggleInquilino,
          ),
        ),
        const SizedBox(height: 12),
        _PaidForAllRow(
          value: form.hoAnticipatoPerTutti,
          onChanged: controller.setHoAnticipatoPerTutti,
        ),
        const SizedBox(height: 12),
        _RecurringRow(
          value: form.spesaRicorrente,
          onChanged: controller.setSpesaRicorrente,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Frequenza',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: form.spesaRicorrente
                  ? AppColors.brandPrimary
                  : const Color(0xFF6A5A86),
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
            enabled: form.spesaRicorrente,
            onChanged: controller.setFrequenza,
          ),
        ),
        if (form.showMissingError) ...[
          const SizedBox(height: 14),
          const _ErrorLine(message: 'Dati mancanti: compila i campi necessari'),
        ],
        const SizedBox(height: 16),
        _PopupSaveButton(
          enabled: form.canSubmit,
          submitting: form.isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

// Form State Management
class _SpesaCreateFormState {
  _SpesaCreateFormState({
    this.importo = '',
    this.descrizione = '',
    this.selectedInquiliniIds = const {},
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
  final bool hoAnticipatoPerTutti;
  final bool spesaRicorrente;
  final String frequenza;
  final bool showErrors;
  final bool isSubmitting;
  final String submitError;

  bool get canSubmit =>
      importo.trim().isNotEmpty &&
      (double.tryParse(importo.trim()) ?? 0) > 0 &&
      selectedInquiliniIds.isNotEmpty &&
      !isSubmitting;

  bool get hasValidImporto =>
      importo.trim().isNotEmpty && (double.tryParse(importo.trim()) ?? 0) > 0;

  bool get showMissingError => submitError.isNotEmpty && showErrors;
}

class _SpesaCreateFormController extends StateNotifier<_SpesaCreateFormState> {
  _SpesaCreateFormController() : super(_SpesaCreateFormState());

  void setImporto(String value) {
    state = _SpesaCreateFormState(
      importo: value,
      descrizione: state.descrizione,
      selectedInquiliniIds: state.selectedInquiliniIds,
      hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
      showErrors: state.showErrors,
    );
  }

  void setDescrizione(String value) {
    state = _SpesaCreateFormState(
      importo: state.importo,
      descrizione: value,
      selectedInquiliniIds: state.selectedInquiliniIds,
      hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
      spesaRicorrente: state.spesaRicorrente,
      frequenza: state.frequenza,
      showErrors: state.showErrors,
    );
  }

  void toggleInquilino(String inquilinoId) {
    final newIds = {...state.selectedInquiliniIds};
    if (newIds.contains(inquilinoId)) {
      newIds.remove(inquilinoId);
    } else {
      newIds.add(inquilinoId);
    }
    state = _SpesaCreateFormState(
      importo: state.importo,
      descrizione: state.descrizione,
      selectedInquiliniIds: newIds,
      hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
      spesaRicorrente: state.spesaRicorrente,
      frequenza: state.frequenza,
      showErrors: state.showErrors,
    );
  }

  void setHoAnticipatoPerTutti(bool value) {
    state = _SpesaCreateFormState(
      importo: state.importo,
      descrizione: state.descrizione,
      selectedInquiliniIds: state.selectedInquiliniIds,
      hoAnticipatoPerTutti: value,
      spesaRicorrente: state.spesaRicorrente,
      frequenza: state.frequenza,
      showErrors: state.showErrors,
    );
  }

  void setSpesaRicorrente(bool value) {
    state = _SpesaCreateFormState(
      importo: state.importo,
      descrizione: state.descrizione,
      selectedInquiliniIds: state.selectedInquiliniIds,
      hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
      spesaRicorrente: value,
      frequenza: state.frequenza,
      showErrors: state.showErrors,
    );
  }

  void setFrequenza(String value) {
    state = _SpesaCreateFormState(
      importo: state.importo,
      descrizione: state.descrizione,
      selectedInquiliniIds: state.selectedInquiliniIds,
      hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
      spesaRicorrente: state.spesaRicorrente,
      frequenza: value,
      showErrors: state.showErrors,
    );
  }

  bool validateBeforeSubmit() {
    final hasValidImporto = state.hasValidImporto;
    final hasInquilini = state.selectedInquiliniIds.isNotEmpty;

    if (!hasValidImporto || !hasInquilini) {
      state = _SpesaCreateFormState(
        importo: state.importo,
        descrizione: state.descrizione,
        selectedInquiliniIds: state.selectedInquiliniIds,
        hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
        spesaRicorrente: state.spesaRicorrente,
        frequenza: state.frequenza,
        showErrors: true,
      );
      return false;
    }
    return true;
  }

  void setSubmitting(bool value) {
    state = _SpesaCreateFormState(
      importo: state.importo,
      descrizione: state.descrizione,
      selectedInquiliniIds: state.selectedInquiliniIds,
      hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
      spesaRicorrente: state.spesaRicorrente,
      frequenza: state.frequenza,
      showErrors: state.showErrors,
      isSubmitting: value,
    );
  }

  void setSubmitError(String error) {
    state = _SpesaCreateFormState(
      importo: state.importo,
      descrizione: state.descrizione,
      selectedInquiliniIds: state.selectedInquiliniIds,
      hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
      spesaRicorrente: state.spesaRicorrente,
      frequenza: state.frequenza,
      showErrors: true,
      submitError: error,
    );
  }
}

// UI Components
class _ImportoField extends StatelessWidget {
  const _ImportoField({
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

class _DescrizioneField extends StatelessWidget {
  const _DescrizioneField({required this.controller, required this.onChanged});

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

class _DivisioneLoading extends StatelessWidget {
  const _DivisioneLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DivisioneSection extends StatelessWidget {
  const _DivisioneSection({
    required this.inquilini,
    required this.selectedIds,
    required this.showError,
    required this.onSelected,
  });

  final List<Inquilino> inquilini;
  final Set<String> selectedIds;
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
        ...inquilini.asMap().entries.map((entry) {
          final inquilino = entry.value;
          final isSelected = selectedIds.contains(inquilino.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InquilinoCheckbox(
              inquilino: inquilino,
              isSelected: isSelected,
              onChanged: () => onSelected(inquilino.id),
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

class _InquilinoCheckbox extends StatelessWidget {
  const _InquilinoCheckbox({
    required this.inquilino,
    required this.isSelected,
    required this.onChanged,
  });

  final Inquilino inquilino;
  final bool isSelected;
  final VoidCallback onChanged;

  Color _getAvatarColor(String id) {
    final colors = [
      const Color(0xFF1B5E20),
      const Color(0xFFE53935),
      const Color(0xFF6D4C41),
      const Color(0xFF1565C0),
    ];
    return colors[id.hashCode % colors.length];
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
          onTap: onChanged,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getAvatarColor(inquilino.id),
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
                    inquilino.nome,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: 14,
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onChanged(),
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

class _PaidForAllRow extends StatelessWidget {
  const _PaidForAllRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Ho anticipato per tutti',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: const Color(0xFF3B3150),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
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

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.statusNegative, size: 20),
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
      ),
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
    return ElevatedButton(
      onPressed: enabled && !submitting ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: submitting
            ? AppColors.textMuted
            : AppColors.brandPrimary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        disabledBackgroundColor: AppColors.textMuted,
      ),
      child: Text(
        'Conferma e aggiungi',
        style: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.textOnDark,
          fontSize: 18,
        ),
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
        backgroundColor: submitting
            ? AppColors.textMuted
            : const Color(0xFFA48DDA),
        disabledBackgroundColor: AppColors.textMuted,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        side: const BorderSide(color: AppColors.statusNegative, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        disabledForegroundColor: AppColors.textMuted.withValues(alpha: 0.5),
      ),
      child: Text(
        'Annulla',
        style: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.statusNegative,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({required this.value, required this.onChanged});

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

class _FrequencyDropdown extends StatelessWidget {
  const _FrequencyDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      'Mensile',
      'Bimestrale',
      'Trimestrale',
      'Annuale',
      'Personalizzata',
    ];
    final selectedValue = options.contains(value) ? value : options.first;
    final textStyle = AppTextStyles.screenTitleStrong.copyWith(
      color: enabled
          ? AppColors.textOnDark
          : AppColors.textOnDark.withValues(alpha: 0.58),
      fontSize: 14,
    );

    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.surfaceDarkElevated
              : AppColors.surfaceDarkElevated.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(color: Colors.transparent),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            items: options
                .map(
                  (opt) => DropdownMenuItem(
                    value: opt,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        opt,
                        style: AppTextStyles.screenTitleStrong.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled
                ? (v) {
                    if (v != null) onChanged(v);
                  }
                : null,
            selectedItemBuilder: (context) => options
                .map(
                  (opt) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(opt, style: textStyle),
                  ),
                )
                .toList(),
            dropdownColor: AppColors.surfaceDarkElevated,
            iconEnabledColor: AppColors.brandPrimary,
            iconDisabledColor: AppColors.brandPrimary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
