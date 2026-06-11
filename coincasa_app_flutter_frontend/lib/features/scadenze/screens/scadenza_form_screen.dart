import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';

class ScadenzaFormScreen extends StatefulWidget {
  final bool isEditing;
  final String initialNome;
  final String initialDescrizione;
  final DateTime? initialData;
  final String initialFrequenza;

  const ScadenzaFormScreen.nuova({super.key})
    : isEditing = false,
      initialNome = '',
      initialDescrizione = '',
      initialData = null,
      initialFrequenza = 'Non ripetere';

  const ScadenzaFormScreen.modifica({
    super.key,
    required String nome,
    required String descrizione,
    required DateTime? data,
    required String frequenza,
  }) : isEditing = true,
       initialNome = nome,
       initialDescrizione = descrizione,
       initialData = data,
       initialFrequenza = frequenza;

  @override
  State<ScadenzaFormScreen> createState() => _ScadenzaFormScreenState();
}

class _ScadenzaFormScreenState extends State<ScadenzaFormScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _descrizioneController;
  late final TextEditingController _dataController;

  late String _frequenza;
  bool _showFrequencyOptions = false;
  bool _hasNameError = false;
  bool _hasDateError = false;
  bool _isHomeAdmin = false;
  bool _initialized = false;

  static const _primary = Color(0xFF5A2BBF);
  static const _danger = Color(0xFFFF1744);
  static const _fieldColor = Color(0xFF302A4C);
  static const _disabled = Color(0xFF9D9D9D);
  static const _accent = Color(0xFF996CFA);
  static const _dropdownColor = Color(0xFF403865);
  static const _frequencyOptions = [
    'Non ripetere',
    'Settimanale',
    'Mensile',
    'Annuale',
    //'Custom',
  ];

  bool get _hasErrors => _hasNameError || _hasDateError;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.initialNome);
    _descrizioneController = TextEditingController(
      text: widget.initialDescrizione,
    );
    _dataController = TextEditingController(
      text: widget.initialData != null ? _formatDate(widget.initialData!) : '',
    );
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _loadCurrentRole();
  }

  Future<void> _loadCurrentRole() async {
    try {
      final activeCasaController = ActiveCasaScope.read(context);
      final caseUtente = await ApiProvider.casa.list();
      if (caseUtente.isEmpty) return;
      final casa = activeCasaController.resolveCasa(caseUtente);
      final inquilini = await ApiProvider.casa.listInquilini(casa.id);
      final current = _resolveCurrentUser(inquilini);
      if (!mounted) return;
      setState(() => _isHomeAdmin = current?.isHomeAdmin == true);
    } catch (_) {}
  }

  Inquilino? _resolveCurrentUser(List<Inquilino> inquilini) {
    final userId = ApiProvider.client.currentUserId?.trim();
    if (userId != null && userId.isNotEmpty) {
      for (final inquilino in inquilini) {
        if (inquilino.id == userId) return inquilino;
      }
    }
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
        return inquilino;
      }
    }
    return inquilini.isNotEmpty ? inquilini.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151127),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFAC86FF)),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          widget.isEditing ? 'Modifica scadenza' : 'Nuova Scadenza',
          style: const TextStyle(
            color: Color(0xFFAC86FF),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LabeledField(
              label: 'Nome scadenza',
              hasError: _hasNameError,
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
                  if (_hasNameError)
                    const _ErrorMessage(text: 'Inserisci un nome'),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Data di scadenza',
              hasError: _hasDateError,
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
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Frequenza',
              child: _isHomeAdmin
                  ? _FrequencySelector(
                      selectedValue: _frequenza,
                      options: _frequencyOptions,
                      isExpanded: _showFrequencyOptions,
                      accent: _accent,
                      dropdownColor: _dropdownColor,
                      onToggle: () => setState(
                        () => _showFrequencyOptions = !_showFrequencyOptions,
                      ),
                      onSelect: (value) => setState(() {
                        _frequenza = value;
                        _showFrequencyOptions = false;
                      }),
                    )
                  : _DisabledFrequencyField(frequenza: _frequenza),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _hasErrors ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: _disabled,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  widget.isEditing ? 'Salva modifiche' : 'Salva scadenza',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF501C26),
                    side: const BorderSide(color: _danger, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(
                      color: _danger,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
    final initial = widget.initialData ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selected == null) return;
    setState(() {
      _dataController.text = _formatDate(selected);
      _hasDateError = !_isFutureDate(selected);
    });
  }

  void _save() {
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

    Navigator.of(context).pop(true);
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
    if (date.day != day || date.month != month || date.year != year)
      return null;
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

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({
    required this.selectedValue,
    required this.options,
    required this.isExpanded,
    required this.accent,
    required this.dropdownColor,
    required this.onToggle,
    required this.onSelect,
  });

  final String selectedValue;
  final List<String> options;
  final bool isExpanded;
  final Color accent;
  final Color dropdownColor;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: const Color(0xFF302A4C),
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
                      color: accent,
                      size: 26,
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
              color: dropdownColor,
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
                        fontSize: 16,
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

class _DisabledFrequencyField extends StatelessWidget {
  const _DisabledFrequencyField({required this.frequenza});
  final String frequenza;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: const Color(0xFF302A4C),
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
                      frequenza,
                      style: const TextStyle(
                        color: Color(0xFFBDB7CC),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF7A6F86),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            '( solo HomeAdmin ) ⚠',
            style: TextStyle(
              color: Colors.amber.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
  });

  final String label;
  final Widget child;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 5),
          child: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                color: Color(0xFF5A2BBF),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              children: hasError
                  ? const [
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Color(0xFFFF1744)),
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
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: Color(0xFFFF1744), size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFF1744),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
