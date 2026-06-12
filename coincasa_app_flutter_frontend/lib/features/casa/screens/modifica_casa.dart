import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

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

  static const double _inputRadius = 18;

  static final TextStyle _sectionLabelStyle = AppTextStyles
      .dashboardSectionTitle
      .copyWith(color: AppColors.textOnDark, fontSize: 12);
  static final TextStyle _inputTextStyle =
      AppTextStyles.inputCompact.copyWith(fontSize: 15);
  static final TextStyle _hintTextStyle = AppTextStyles.bodyMuted
      .copyWith(color: AppColors.textMutedDark, fontSize: 15);
  static final TextStyle _buttonTextStyle =
      AppTextStyles.buttonCompact.copyWith(fontSize: 16);

  @override
  void initState() {
    super.initState();
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

  bool get _isFormValid =>
      _nameController.text.trim().length > 3 &&
      (_selectedType?.isNotEmpty ?? false);

  Future<void> _handleSave() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showValidationError = !isValid);
    if (!isValid) return;

    setState(() => _isSaving = true);
    try {
      await ApiProvider.casa.update(widget.casaId, {
        'nome': _nameController.text.trim(),
        'citta': _cityController.text.trim(),
        'indirizzo': _addressController.text.trim(),
        'tipoCasa': _selectedType ?? '',
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifica casa non riuscita.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textOnDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: Navigator.of(context).pop,
          ),
          title: const Text('Modifica', style: AppTextStyles.screenTitle),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p20,
              vertical: AppSizes.p8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Errore validazione ───────────────────────────────────
                if (_showValidationError)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p16,
                      vertical: AppSizes.p16,
                    ),
                    margin: const EdgeInsets.only(bottom: AppSizes.p20),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainerDark,
                      borderRadius: BorderRadius.circular(_inputRadius),
                      border: Border.all(
                        color: AppColors.errorStrong,
                        width: 1.3,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Campi non validi', style: AppTextStyles.error),
                        SizedBox(height: 8),
                        Text(
                          'Inserisci un nome valido con più di 3 lettere e seleziona il tipo di abitazione per proseguire',
                          style: AppTextStyles.errorCompact,
                        ),
                      ],
                    ),
                  ),

                // ── Immagine casa ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSizes.radius24),
                    border: Border.all(
                      color: AppColors.brandAccent,
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    height: 230,
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
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.p16,
                              vertical: AppSizes.p12,
                            ),
                            child: Image.asset(
                              'assets/Icons/appartamenti-moderni-lusso 1.png',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // ── Banner modifica ────────────────────────────
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            color: AppColors.brandPrimary.withValues(alpha: 0.88),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Stai modificando le informazioni',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.p24),

                // ── Form ─────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  autovalidateMode: _showValidationError
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NOME DELLA CASA *', style: _sectionLabelStyle),
                      const SizedBox(height: AppSizes.p8),
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
                      const SizedBox(height: AppSizes.p16),

                      Text('CITTÀ (opzionale)', style: _sectionLabelStyle),
                      const SizedBox(height: AppSizes.p8),
                      _buildTextField(
                        controller: _cityController,
                        hintText: 'es. Roma',
                      ),
                      const SizedBox(height: AppSizes.p16),

                      Text('INDIRIZZO (opzionale)', style: _sectionLabelStyle),
                      const SizedBox(height: AppSizes.p8),
                      _buildTextField(
                        controller: _addressController,
                        hintText: 'es. Via del Corso, 12',
                      ),
                      const SizedBox(height: AppSizes.p16),

                      Text('TIPO DI ABITAZIONE *', style: _sectionLabelStyle),
                      const SizedBox(height: AppSizes.p8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: _inputDecoration(hintText: 'Seleziona tipo'),
                        dropdownColor: AppColors.inputFillDark,
                        borderRadius: BorderRadius.circular(AppSizes.radius16),
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
                          color: AppColors.textOnDark,
                        ),
                        style: _inputTextStyle,
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
                      const SizedBox(height: AppSizes.p28),

                      // ── Step dots ──────────────────────────────────────
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStepDot(active: true),
                            const SizedBox(width: AppSizes.p8),
                            _buildStepDot(active: false),
                            const SizedBox(width: AppSizes.p8),
                            _buildStepDot(active: false),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.p24),

                      FilledButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSizes.p56),
                          backgroundColor: _isFormValid
                              ? AppColors.brandPrimary
                              : AppColors.brandPrimary.withValues(alpha: 0.8),
                          foregroundColor: AppColors.textOnDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_inputRadius),
                          ),
                        ),
                        child: Text(
                          _isSaving ? 'Salvataggio...' : 'Salva modifiche',
                          style: _buttonTextStyle,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p24),
                    ],
                  ),
                ),
              ],
            ),
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
      style: _inputTextStyle,
      decoration: _inputDecoration(hintText: hintText),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.inputFillDark,
      hintText: hintText,
      hintStyle: _hintTextStyle,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p18,
        vertical: AppSizes.p18,
      ),
      errorStyle: AppTextStyles.fieldError.copyWith(
        color: AppColors.errorStrong,
        fontSize: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: const BorderSide(color: AppColors.dividerDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: const BorderSide(color: AppColors.dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: const BorderSide(color: AppColors.errorStrong, width: 1.8),
      ),
    );
  }

  Widget _buildStepDot({required bool active}) {
    return Container(
      width: AppSizes.p12,
      height: AppSizes.p12,
      decoration: BoxDecoration(
        color: active ? AppColors.brandPrimary : AppColors.dividerOnDark,
        borderRadius: BorderRadius.circular(AppSizes.p6),
      ),
    );
  }
}
