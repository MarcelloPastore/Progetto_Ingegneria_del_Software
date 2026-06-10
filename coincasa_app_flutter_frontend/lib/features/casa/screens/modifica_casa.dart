import 'package:flutter/material.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';

class ModificaCasaScreen extends StatefulWidget {
  final String casaId;
  final String name;
  final String city;
  final String address;
  final String type;

  const ModificaCasaScreen({
    super.key,
    required this.casaId,
    required this.name,
    required this.city,
    required this.address,
    required this.type,
  });

  @override
  State<ModificaCasaScreen> createState() => _ModificaCasaScreenState();
}

class _ModificaCasaScreenState extends State<ModificaCasaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late String? _selectedType;
  bool _showValidationError = false;
  bool _isSaving = false;

  static const _backgroundColor = Color(0xFF0B0828);
  static const _cardColor = Color(0xFF151138);
  static const _fieldColor = Color(0xFF12102B);

  @override
  void initState() {
    super.initState();
    // Pre-compila i campi con i dati esistenti
    _nameController = TextEditingController(text: widget.name);
    _cityController = TextEditingController(text: widget.city);
    _addressController = TextEditingController(text: widget.address);
    _selectedType = widget.type.isNotEmpty ? widget.type : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _nameController.text.trim().length > 3 &&
        (_selectedType?.isNotEmpty ?? false);
  }

  Future<void> _handleSave() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _showValidationError = !isValid;
    });

    if (isValid) {
      setState(() {
        _isSaving = true;
      });

      try {
        await ApiProvider.casa.update(widget.casaId, {
          'nome': _nameController.text.trim(),
          'citta': _cityController.text.trim(),
          'indirizzo': _addressController.text.trim(),
          'tipoCasa': _selectedType ?? '',
        });
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(true);
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifica casa non riuscita.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: Navigator.of(context).pop,
        ),
        title: const Text(
          'Modifica informazioni\ndella casa',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Immagine casa ──────────────────────────────────────────
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B3A5E), width: 1),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF21154C), Color(0xFF0F0A27)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/Icons/appartamenti-moderni-lusso 1.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.home_outlined,
                              color: Color(0xFF3B3A5E),
                              size: 64,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Form ───────────────────────────────────────────────────
              if (_showValidationError)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B102D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF5A7D),
                      width: 1.3,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campi non validi',
                        style: TextStyle(
                          color: Color(0xFFFF5A7D),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Inserisci un nome valido con più di 3 lettere e seleziona il tipo di abitazione per proseguire',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              Form(
                key: _formKey,
                autovalidateMode: _showValidationError
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome
                    const _FieldLabel(text: 'NOME DELLA CASA', required: true),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'es. Casa Rossi',
                      onChanged: (_) {
                        if (_showValidationError) setState(() {});
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Inserisci il nome della casa';
                        }
                        if (value.trim().length <= 3) {
                          return 'Il nome deve contenere più di 3 lettere';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Città
                    const _FieldLabel(text: 'CITTÀ (opzionale)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _cityController,
                      hintText: 'es. Roma',
                    ),
                    const SizedBox(height: 16),

                    // Indirizzo
                    const _FieldLabel(text: 'INDIRIZZO (opzionale)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'es. Via del Corso, 12',
                    ),
                    const SizedBox(height: 16),

                    // Tipo abitazione
                    const _FieldLabel(
                      text: 'TIPO DI ABITAZIONE',
                      required: true,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: _inputDecoration(hintText: 'Seleziona tipo'),
                      dropdownColor: _fieldColor,
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(
                          value: 'Appartamento condiviso',
                          child: Text('Appartamento condiviso'),
                        ),
                        DropdownMenuItem(
                          value: 'Studentato/Residenza',
                          child: Text('Studentato/Residenza'),
                        ),
                        DropdownMenuItem(
                          value: 'Casa indipendente condivisa',
                          child: Text('Casa indipendente condivisa'),
                        ),
                      ],
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (value) => setState(() {
                        _selectedType = value;
                        if (_showValidationError) {}
                      }),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Seleziona il tipo di abitazione';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Step dots
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepDot(active: true),
                          const SizedBox(width: 8),
                          _buildStepDot(active: false),
                          const SizedBox(width: 8),
                          _buildStepDot(active: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bottone Salva modifiche
                    FilledButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: _isFormValid
                            ? AppColors.brandPrimary
                            : AppColors.brandPrimary.withValues(alpha: 0.8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _isSaving ? 'Salvataggio...' : 'Salva modifiche',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: _inputDecoration(hintText: hintText),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: _fieldColor,
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF6E6B8F)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      errorStyle: const TextStyle(color: Color(0xFFFF5A7D), fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF3B3A5E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF3B3A5E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF5A7D), width: 1.8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF5A7D), width: 1.8),
      ),
    );
  }

  Widget _buildStepDot({required bool active}) {
    return Container(
      width: active ? 24 : 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppColors.brandPrimary : const Color(0xFF4B4A78),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ── Label campo con asterisco opzionale ──────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _FieldLabel({required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFFF5A7D),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
