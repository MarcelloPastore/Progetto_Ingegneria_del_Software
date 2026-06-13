import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/state/active_casa_session.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/fab_buttons.dart';

import 'fab_sacdenza_creata.dart';

class FabScadenzaPanel extends StatefulWidget {
  const FabScadenzaPanel({super.key});

  @override
  State<FabScadenzaPanel> createState() => _FabScadenzaPanelState();
}

class _FabScadenzaPanelState extends State<FabScadenzaPanel> {
  final _nomeController = TextEditingController();
  final _descrizioneController = TextEditingController();
  final _dataController = TextEditingController();

  String _frequenza = 'Non ripetere';
  bool _showFrequencyOptions = false;
  bool _hasNameError = false;
  bool _hasDateError = false;
  bool _isCreated = false;
  bool _isSaving = false;

  static const _danger = Color(0xFFFF1744);
  static const _fieldColor = Color(0xFF302A4C);
  static const _frequencyOptions = [
    'Non ripetere',
    'Settimanale',
    'Mensile',
    'Annuale',
    'Custom',
  ];

  bool get _hasErrors => _hasNameError || _hasDateError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dataController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
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
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'Nome scadenza',
          required: _hasNameError,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                onChanged: (_) => _clearNameErrorIfValid(),
                style: TextStyle(
                  color: _hasNameError ? _danger : Colors.white,
                  fontSize: 18,
                ),
                decoration: _inputDecoration(
                  'Es. Revisione caldaia',
                  hasError: _hasNameError,
                ),
              ),
              if (_hasNameError) const _ErrorMessage(text: 'Inserisci un nome'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _LabeledField(
          label: 'Descrizione (opzionale)',
          child: TextFormField(
            controller: _descrizioneController,
            minLines: 1,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: _inputDecoration('Es. Revisione annuale'),
          ),
        ),
        const SizedBox(height: 8),
        _LabeledField(
          label: 'Data di scadenza',
          required: _hasDateError,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _dataController,
                readOnly: true,
                onTap: _pickDate,
                style: TextStyle(
                  color: _hasDateError ? _danger : Colors.white,
                  fontSize: 18,
                ),
                decoration: _inputDecoration(
                  'GG/MM/AAAA',
                  hasError: _hasDateError,
                ),
              ),
              if (_hasDateError)
                const _ErrorMessage(text: 'La data deve essere futura'),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 18),
        FabSaveButton(
          label: 'Salva scadenza',
          onPressed: _hasErrors ? null : _save,
          isLoading: _isSaving,
        ),
        const SizedBox(height: 14),
        FabCancelButton(onPressed: () => Navigator.of(context).maybePop()),
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint, {bool hasError = false}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: hasError
          ? const BorderSide(color: _danger, width: 2)
          : BorderSide.none,
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDB7CC), fontSize: 18),
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );

    if (selected == null) {
      return;
    }

    final day = selected.day.toString().padLeft(2, '0');
    final month = selected.month.toString().padLeft(2, '0');
    final year = selected.year.toString();

    setState(() {
      _dataController.text = '$day/$month/$year';
      _hasDateError = !_isFutureDate(selected);
    });
  }

  Future<void> _save() async {
    final selectedDate = _parseDate(_dataController.text);
    final hasNameError = _nomeController.text.trim().isEmpty;
    final hasDateError = selectedDate == null || !_isFutureDate(selectedDate);

    if (hasNameError || hasDateError) {
      setState(() {
        _hasNameError = hasNameError;
        _hasDateError = hasDateError;
      });
      return;
    }

    // Capture context-dependent values before any async gap
    final activeCasa = ActiveCasaScope.read(context);
    final cadenzaGiorni = _cadenzaFromFrequenza(_frequenza);
    final isRicorrente = cadenzaGiorni != null;
    final nome = _nomeController.text.trim();
    final descrizione = _descrizioneController.text.trim();
    final dataIso = _payloadDate(selectedDate).toIso8601String();

    setState(() => _isSaving = true);
    try {
      final casa = await ensureActiveCasaContext(activeCasa);
      await ApiProvider.scadenze.create(casa.id, {
        'nome': nome,
        'descrizione': descrizione,
        'dataScadenza': dataIso,
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
    setState(() {
      _nomeController.clear();
      _descrizioneController.clear();
      _dataController.clear();
      _frequenza = 'Non ripetere';
      _showFrequencyOptions = false;
      _hasNameError = false;
      _hasDateError = false;
      _isCreated = false;
    });
  }

  void _clearNameErrorIfValid() {
    if (!_hasNameError || _nomeController.text.trim().isEmpty) {
      return;
    }

    setState(() => _hasNameError = false);
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

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
          color: _FabColors.fieldColor,
          borderRadius: BorderRadius.circular(7),
          elevation: 4,
          shadowColor: Colors.black45,
          child: SizedBox(
            height: 41,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedValue,
                      style: const TextStyle(
                        color: Color(0xFFBDB7CC),
                        fontSize: 18,
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
                      color: _FabColors.accent,
                      size: 26,
                    ),
                    tooltip: isExpanded ? 'Chiudi frequenza' : 'Apri frequenza',
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
              color: _FabColors.dropdownColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(7),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0x338B7BC7)),
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFC493FF)
                            : const Color(0xFFD4D0DF),
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
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
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: RichText(
            text: TextSpan(
              text: label.toUpperCase(),
              style: const TextStyle(
                color: _primaryLabel,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              children: required
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: _FabColors.danger),
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

  static const _primaryLabel = Color(0xFF5228AD);
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: _FabColors.danger, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _FabColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FabColors {
  const _FabColors._();

  static const accent = Color(0xFF996CFA);
  static const danger = Color(0xFFFF1744);
  static const fieldColor = Color(0xFF302A4C);
  static const dropdownColor = Color(0xFF403865);
}
