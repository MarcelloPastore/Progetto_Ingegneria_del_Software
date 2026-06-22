import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/app_cancel_button.dart';
import 'package:coincasa_app/core/widgets/common/fab_salva_button.dart';
import 'package:coincasa_app/domain/viewmodel/scadenze_viewmodel.dart';

import 'fab_scadenza_creata.dart';

class FabScadenzaPanel extends ConsumerStatefulWidget {
  const FabScadenzaPanel({super.key});

  @override
  ConsumerState<FabScadenzaPanel> createState() => _FabScadenzaPanelState();
}

class _FabScadenzaPanelState extends ConsumerState<FabScadenzaPanel> {
  final _nomeController = TextEditingController();
  final _descrizioneController = TextEditingController();
  final _dataController = TextEditingController();

  String _frequenza = 'Non ripetere';
  bool _showFrequencyOptions = false;
  bool _hasNameError = false;
  bool _isCreated = false;
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
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _dataController.text =
        '${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.year}';
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
    if (_isCreated) {
      return FabScadenzaCreataPanel(
        onBackToScadenze: _goToScadenze,
        onAddAnother: _resetForm,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nuova Scadenza',
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.brandPrimary,
            fontSize: AppSizes.p23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        _LabeledField(
          label: 'Nome scadenza',
          required: true,
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
                  context,
                  'Es. Revisione caldaia',
                  hasError: _hasNameError,
                ),
              ),
              if (_hasNameError)
                const _ErrorMessage(text: 'Inserisci un nome'),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        _LabeledField(
          label: 'Descrizione (opzionale)',
          child: TextFormField(
            controller: _descrizioneController,
            minLines: 1,
            maxLines: 2,
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p18,
            ),
            decoration: _inputDecoration(context, 'Es. Revisione annuale'),
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        _LabeledField(
          label: 'Data di scadenza',
          child: TextFormField(
            controller: _dataController,
            readOnly: true,
            onTap: _pickDate,
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p18,
            ),
            decoration: _inputDecoration(context, 'GG/MM/AAAA'),
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        _LabeledField(
          label: 'Frequenza',
          child: _FrequencySelector(
            selectedValue: _frequenza,
            options: _frequencyOptions,
            isExpanded: _showFrequencyOptions,
            onToggle: () {
              setState(() => _showFrequencyOptions = !_showFrequencyOptions);
            },
            onSelect: (value) {
              setState(() {
                _frequenza = value;
                _showFrequencyOptions = false;
              });
            },
          ),
        ),
        const SizedBox(height: AppSizes.p18),
        FabSaveButton(
          label: 'Salva scadenza',
          onPressed: _hasErrors ? null : _save,
          isLoading: _isSaving,
        ),
        const SizedBox(height: AppSizes.p14),
        AppCancelButton(onPressed: () => Navigator.of(context).maybePop()),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
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
    final selected = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 10),
    );

    if (selected == null) return;

    final day = selected.day.toString().padLeft(2, '0');
    final month = selected.month.toString().padLeft(2, '0');
    final year = selected.year.toString();

    setState(() {
      _dataController.text = '$day/$month/$year';
    });
  }

  Future<void> _save() async {
    if (_nomeController.text.trim().isEmpty) {
      setState(() => _hasNameError = true);
      return;
    }

    final selectedDate = _parseDate(_dataController.text);
    final validDate = selectedDate != null && _isFutureDate(selectedDate)
        ? selectedDate
        : null;

    final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
    if (casaId.isEmpty) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    final cadenzaGiorni = _cadenzaFromFrequenza(_frequenza);
    final isRicorrente = cadenzaGiorni != null;
    final nome = _nomeController.text.trim();
    final descrizione = _descrizioneController.text.trim();
    final dataIso = validDate != null
        ? _payloadDate(validDate).toIso8601String()
        : null;

    setState(() => _isSaving = true);
    try {
      await ref.read(scadenzeViewModelProvider(casaId).notifier).createScadenza({
        'nome': nome,
        'descrizione': descrizione,
        if (dataIso != null) 'dataScadenza': dataIso,
        'isRicorrente': isRicorrente,
        if (cadenzaGiorni != null) 'cadenzaGiorni': cadenzaGiorni,
      });

      if (mounted) setState(() => _isCreated = true);
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

  void _goToScadenze() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pushNamed('/scadenze');
  }

  void _resetForm() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      _nomeController.clear();
      _descrizioneController.clear();
      _dataController.text =
          '${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.year}';
      _frequenza = 'Non ripetere';
      _showFrequencyOptions = false;
      _hasNameError = false;
      _isCreated = false;
    });
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
              padding: const EdgeInsets.only(
                left: AppSizes.p12,
                right: AppSizes.p4,
              ),
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
                    tooltip:
                        isExpanded ? 'Chiudi frequenza' : 'Apri frequenza',
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
                        fontSize: AppSizes.p13,
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
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSizes.p2, bottom: AppSizes.p4),
          child: RichText(
            text: TextSpan(
              text: label.toUpperCase(),
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontSize: AppSizes.p13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              children: required
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
