import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/app_cancel_button.dart';
import 'package:coincasa_app/core/widgets/common/app_submit_button.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/domain/viewmodel/scadenze_viewmodel.dart';

class ScadenzaFormScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final String initialNome;
  final String initialDescrizione;
  final DateTime? initialData;
  final String initialFrequenza;
  final String? idScadenza;
  final String? casaId;

  const ScadenzaFormScreen.nuova({super.key})
    : isEditing = false,
      initialNome = '',
      initialDescrizione = '',
      initialData = null,
      initialFrequenza = 'Non ripetere',
      idScadenza = null,
      casaId = null;

  const ScadenzaFormScreen.modifica({
    super.key,
    required String nome,
    required String descrizione,
    required DateTime? data,
    required String frequenza,
    required this.idScadenza,
    required this.casaId,
  }) : isEditing = true,
       initialNome = nome,
       initialDescrizione = descrizione,
       initialData = data,
       initialFrequenza = frequenza;

  @override
  ConsumerState<ScadenzaFormScreen> createState() => _ScadenzaFormScreenState();
}

class _ScadenzaFormScreenState extends ConsumerState<ScadenzaFormScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _descrizioneController;
  late final TextEditingController _dataController;

  late String _frequenza;
  bool _showFrequencyOptions = false;
  bool _hasNameError = false;
  bool _isSaving = false;

  static const _frequencyOptions = [
    'Non ripetere',
    'Settimanale',
    'Mensile',
    'Annuale',
  ];

  bool get _hasErrors => _hasNameError;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.initialNome);
    _descrizioneController = TextEditingController(
      text: widget.initialDescrizione,
    );
    final now = DateTime.now();
    final defaultDate = widget.isEditing
        ? (widget.initialData ?? now)
        : DateTime(now.year, now.month, now.day + 1);
    _dataController = TextEditingController(text: _formatDate(defaultDate));
    _frequenza = widget.initialFrequenza;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descrizioneController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: cs.surface,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/scadenze'),
        appBar: AppBar(
          systemOverlayStyle: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.isEditing
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.brandAccent),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          title: Text(
            widget.isEditing ? 'Modifica scadenza' : 'Nuova Scadenza',
            style: TextStyle(
              color: AppColors.brandAccent,
              fontSize: AppSizes.p22,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p20,
            vertical: AppSizes.p8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledField(
                label: 'Nome scadenza',
                showRequired: true,
                hasError: _hasNameError,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      onChanged: (_) => _clearNameErrorIfValid(),
                      style: TextStyle(
                        color: _hasNameError
                            ? AppColors.errorStrong
                            : AppColors.textOnDark,
                        fontSize: AppSizes.p18,
                      ),
                      decoration: _inputDecoration(
                        cs,
                        'Es. Revisione caldaia',
                        hasError: _hasNameError,
                      ),
                    ),
                    if (_hasNameError)
                      _ErrorMessage(text: 'Inserisci un nome'),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              _LabeledField(
                label: 'Descrizione',
                child: TextFormField(
                  controller: _descrizioneController,
                  minLines: 1,
                  maxLines: 2,
                  style: TextStyle(color: AppColors.textOnDark, fontSize: AppSizes.p18),
                  decoration: _inputDecoration(cs, 'Es. Revisione annuale'),
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              _LabeledField(
                label: 'Data di scadenza',
                child: TextFormField(
                  controller: _dataController,
                  readOnly: true,
                  onTap: _pickDate,
                  style: TextStyle(color: AppColors.textOnDark, fontSize: AppSizes.p18),
                  decoration: _inputDecoration(cs, 'GG/MM/AAAA'),
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              _LabeledField(
                label: 'Frequenza',
                child: _FrequencySelector(
                  selectedValue: _frequenza,
                  options: _frequencyOptions,
                  isExpanded: _showFrequencyOptions,
                  onToggle: () => setState(
                    () => _showFrequencyOptions = !_showFrequencyOptions,
                  ),
                  onSelect: (value) => setState(() {
                    _frequenza = value;
                    _showFrequencyOptions = false;
                  }),
                ),
              ),
              const SizedBox(height: AppSizes.p28),
              AppSubmitButton(
                label: widget.isEditing ? 'Salva modifiche' : 'Salva scadenza',
                isLoading: _isSaving,
                enabled: !_hasErrors && !_isSaving,
                onPressed: _save,
              ),
              const SizedBox(height: AppSizes.p14),
              AppCancelButton(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AppSizes.p24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    ColorScheme cs,
    String? hint, {
    bool hasError = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.p7),
      borderSide: hasError
          ? BorderSide(color: AppColors.errorStrong, width: 2)
          : BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textMutedLight,
        fontSize: AppSizes.p18,
      ),
      filled: true,
      fillColor: AppColors.surfaceDarkMuted,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p10,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final firstDate = widget.isEditing ? DateTime(now.year, now.month, now.day) : tomorrow;
    final initial = widget.initialData ?? tomorrow;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(firstDate) ? initial : firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 10),
    );
    if (selected == null) return;
    setState(() {
      _dataController.text = _formatDate(selected);
    });
  }

  Future<void> _save() async {
    final hasNameError = _nomeController.text.trim().isEmpty;
    if (hasNameError) {
      setState(() => _hasNameError = true);
      return;
    }

    final selectedDate = _parseDate(_dataController.text);
    final validDate = selectedDate != null && _isFutureDate(selectedDate)
        ? selectedDate
        : null;

    final activeCasa = ActiveCasaScope.read(context);
    final cadenzaGiorni = _cadenzaFromFrequenza(_frequenza);
    final isRicorrente = cadenzaGiorni != null;
    final nome = _nomeController.text.trim();
    final descrizione = _descrizioneController.text.trim();
    final dataIso = validDate != null
        ? _payloadDate(validDate).toIso8601String()
        : null;

    final casaId = (widget.casaId?.isNotEmpty == true
            ? widget.casaId
            : activeCasa.selectedCasaId) ??
        '';
    if (casaId.isEmpty) {
      setState(() => _isSaving = false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.isEditing && widget.idScadenza != null) {
        await ref
            .read(scadenzeViewModelProvider(casaId).notifier)
            .updateScadenza(
              widget.idScadenza!,
              datiPayload: {
                'nome': nome,
                'descrizione': descrizione,
                if (dataIso != null) 'dataScadenza': dataIso,
              },
              ricorrenzaPayload: {
                'isRicorrente': isRicorrente,
                if (cadenzaGiorni != null) 'cadenzaGiorni': cadenzaGiorni,
              },
            );
      } else {
        await ref
            .read(scadenzeViewModelProvider(casaId).notifier)
            .createScadenza({
              'nome': nome,
              'descrizione': descrizione,
              if (dataIso != null) 'dataScadenza': dataIso,
              'isRicorrente': isRicorrente,
              if (cadenzaGiorni != null) 'cadenzaGiorni': cadenzaGiorni,
            });
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio: $e')),
        );
      }
    }
  }

  static int? _cadenzaFromFrequenza(String frequenza) {
    switch (frequenza) {
      case 'Settimanale':
        return 7;
      case 'Mensile':
        return 30;
      case 'Annuale':
        return 365;
      default:
        return null;
    }
  }

  static DateTime _payloadDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day, 12);
  }

  void _clearNameErrorIfValid() {
    if (!_hasNameError || _nomeController.text.trim().isEmpty) return;
    setState(() => _hasNameError = false);
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }
    return date;
  }

  bool _isFutureDate(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.isAfter(normalizedToday);
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({
    required this.selectedValue,
    required this.options,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelect,
  });

  final String selectedValue;
  final List<String> options;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surfaceDarkMuted,
          borderRadius: BorderRadius.circular(AppSizes.p7),
          elevation: 4,
          shadowColor: Colors.black45,
          child: SizedBox(
            height: 41,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSizes.p12, right: AppSizes.p4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedValue,
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: AppSizes.p18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.featureAccent,
                      size: AppSizes.p26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkMuted,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSizes.p7),
              ),
              border: Border.all(color: const Color(0x668B7BC7)),
            ),
            child: Column(
              children: options.map((option) {
                final selected = option == selectedValue;
                return InkWell(
                  onTap: () => onSelect(option),
                  child: Container(
                    height: 34,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0x338B7BC7)),
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: selected
                            ? AppColors.featureAccent
                            : AppColors.textOnDark,
                        fontSize: AppSizes.p16,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.hasError = false,
    this.showRequired = false,
  });

  final String label;
  final Widget child;
  final bool hasError;
  final bool showRequired;

  @override
  Widget build(BuildContext context) {
    final showAsterisk = showRequired || hasError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSizes.p5, bottom: AppSizes.p5),
          child: RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontSize: AppSizes.p16,
                fontWeight: FontWeight.w800,
              ),
              children: showAsterisk
                  ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.errorStrong),
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p5),
      child: Row(
        children: [
          Icon(
            Icons.error_rounded,
            color: AppColors.errorStrong,
            size: AppSizes.p14,
          ),
          const SizedBox(width: AppSizes.p5),
          Text(
            text,
            style: TextStyle(
              color: AppColors.errorStrong,
              fontSize: AppSizes.p12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
