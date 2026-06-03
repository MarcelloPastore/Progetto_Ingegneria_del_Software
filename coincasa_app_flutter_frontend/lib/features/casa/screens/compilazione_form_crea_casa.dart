import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coincasa_app/features/casa/screens/riepilogo_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class CompilazioneFormCreaCasaScreen extends StatefulWidget {
  const CompilazioneFormCreaCasaScreen({
    super.key,
    this.name,
    this.city,
    this.address,
    this.type,
    this.fromSummary = false,
  });

  final String? name;
  final String? city;
  final String? address;
  final String? type;
  final bool fromSummary;

  @override
  State<CompilazioneFormCreaCasaScreen> createState() =>
      _CompilazioneFormCreaCasaScreenState();
}

class _CompilazioneFormCreaCasaScreenState
    extends State<CompilazioneFormCreaCasaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedType;
  bool _showValidationError = false;

  static const double _inputRadius = 18;

  static final TextStyle _sectionLabelStyle = AppTextStyles
      .dashboardSectionTitle
      .copyWith(color: AppColors.textOnDark, fontSize: 12);
  static final TextStyle _inputTextStyle = AppTextStyles.inputCompact.copyWith(
    fontSize: 15,
  );
  static final TextStyle _hintTextStyle = AppTextStyles.bodyMuted.copyWith(
    color: AppColors.textMutedDark,
    fontSize: 15,
  );
  static final TextStyle _buttonTextStyle = AppTextStyles.buttonCompact
      .copyWith(fontSize: 16);
  static final TextStyle _fieldErrorStyle = AppTextStyles.fieldError.copyWith(
    color: AppColors.errorStrong,
    fontSize: 12,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers if values were passed
    if (widget.name != null) _nameController.text = widget.name!;
    if (widget.city != null) _cityController.text = widget.city!;
    if (widget.address != null) _addressController.text = widget.address!;
    if (widget.type != null) _selectedType = widget.type;
  }

  bool get _isFormValid {
    return _nameController.text.trim().length > 3 &&
        (_selectedType?.isNotEmpty ?? false);
  }

  void _handleNext() {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _showValidationError = !isValid;
    });

    if (isValid) {
      if (widget.fromSummary) {
        Navigator.of(context).pop(<String, String>{
          'name': _nameController.text.trim(),
          'city': _cityController.text.trim(),
          'address': _addressController.text.trim(),
          'type': _selectedType ?? '',
        });
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RiepilogoCasaScreen(
            name: _nameController.text.trim(),
            city: _cityController.text.trim(),
            address: _addressController.text.trim(),
            type: _selectedType ?? '',
          ),
        ),
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
          title: const Text('Crea la tua casa', style: AppTextStyles.screenTitle),
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
                const Text(
                  'Inserisci le informazioni della tua casa',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSizes.p20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Campi non validi', style: AppTextStyles.error),
                        SizedBox(height: 8),
                        Text(
                          'Inserisci un nome valido con più di 3 lettere e seleziona il tipo di abitazione per proseguire',
                          style: AppTextStyles.errorCompact,
                        ),
                      ],
                    ),
                  ),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSizes.radius24),
                    border: Border.all(color: AppColors.dividerDark, width: 1),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      SizedBox(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.p24),
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
                        }),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleziona il tipo di abitazione';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.p28),
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
                        onPressed: _handleNext,
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
                        child: Text('Avanti', style: _buttonTextStyle),
                      ),
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
      errorStyle: _fieldErrorStyle,
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
