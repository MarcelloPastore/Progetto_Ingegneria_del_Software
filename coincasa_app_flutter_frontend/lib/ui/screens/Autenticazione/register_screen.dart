import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'check_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _campiNonCompilati = false;
  bool _emailEsistente = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _nomeController.dispose();
    _cognomeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _registrati() {
    setState(() {
      _campiNonCompilati = false;
      _emailEsistente = false;
    });

    final username = _usernameController.text.trim();
    final nome = _nomeController.text.trim();
    final cognome = _cognomeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty ||
        nome.isEmpty ||
        cognome.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _campiNonCompilati = true;
      });
      return;
    }

    // Validazione email
    if (!email.contains('@') ||
        !(email.endsWith('.com') || email.endsWith('.it'))) {
      setState(() {
        _campiNonCompilati = true;
      });
      return;
    }

    // Validazione password
    if (password != confirmPassword) {
      setState(() {
        _campiNonCompilati = true;
      });
      return;
    }

    // Qui andrebbe il controllo dell'email esistente tramite chiamata backend, per ora passiamo oltre.

    // Se tutto va a buon fine, push alla schermata di check email
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckEmailScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4C2A9E);
    const Color textPurple = Color(0xFF996CFA);
    const Color textGrey = Color(0xFF8C8C96);
    const Color defaultBorder = Color(0xFF3B3B54);

    const Color errorColor = Color(0xFFD32F2F);
    const Color errorBgColor = Color(0xFF3A0B0B);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF090616),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 0.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crea il tuo account',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                if (_campiNonCompilati || _emailEsistente) ...[
                  const SizedBox(height: 16.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: errorBgColor,
                      border: Border.all(color: errorColor, width: 1.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(
                            0xFFF9A825,
                          ), // Arancione/Giallo come da screen
                          size: 27.0,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: _emailEsistente
                              ? RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ).withValues(alpha: 0.9),
                                      fontSize: 13.0,
                                      height: 1.3,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            "L'email inserita è gia associata a un account esistente. ",
                                      ),
                                      TextSpan(
                                        text: 'Accedi',
                                        style: const TextStyle(
                                          color: Color(0xFF8A72D9),
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.pop(
                                              context,
                                              _emailController.text,
                                            ); // Torna indietro alla schermata di Login
                                          },
                                      ),
                                      const TextSpan(
                                        text:
                                            " oppure utilizza un'altra email.",
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
                                  'Alcuni campi non sono stati compilati correttamente. Controlla i dati inseriti e riprova.',
                                  style: TextStyle(
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ).withValues(alpha: 0.9),
                                    fontSize: 13.0,
                                    height: 1.3,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ] else ...[
                  const SizedBox(height: 12.0),
                ],

                // Form di registrazione
                _buildFieldLabel('Nome Utente', textPurple),
                _buildTextField(
                  controller: _usernameController,
                  borderColor: _campiNonCompilati ? errorColor : defaultBorder,
                  hint: 'Marco_Rossi',
                  errorText: _campiNonCompilati ? 'Campo obbligatorio *' : null,
                ),

                const SizedBox(height: 12.0),
                _buildFieldLabel('Nome', textPurple),
                _buildTextField(
                  controller: _nomeController,
                  borderColor: _campiNonCompilati ? errorColor : defaultBorder,
                  hint: 'Marco',
                  errorText: _campiNonCompilati ? 'Campo obbligatorio *' : null,
                ),

                const SizedBox(height: 12.0),
                _buildFieldLabel('Cognome', textPurple),
                _buildTextField(
                  controller: _cognomeController,
                  borderColor: _campiNonCompilati ? errorColor : defaultBorder,
                  hint: 'Rossi',
                  errorText: _campiNonCompilati ? 'Campo obbligatorio *' : null,
                ),

                const SizedBox(height: 12.0),
                _buildFieldLabel('Email', textPurple),
                _buildTextField(
                  controller: _emailController,
                  borderColor: (_campiNonCompilati || _emailEsistente)
                      ? errorColor
                      : defaultBorder,
                  hint: 'marco@gmail.com',
                  errorText: _campiNonCompilati ? 'Campo obbligatorio *' : null,
                ),

                const SizedBox(height: 12.0),
                _buildFieldLabel('Password', textPurple),
                _buildTextField(
                  controller: _passwordController,
                  borderColor: _campiNonCompilati ? errorColor : defaultBorder,
                  obscureText: _obscurePassword,
                  hint: '••••••••',
                  errorText: _campiNonCompilati ? 'Campo obbligatorio *' : null,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      child: Text(
                        _obscurePassword ? 'Mostra' : 'Nascondi',
                        style: const TextStyle(
                          color: Color(0xFF8A72D9),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12.0),
                _buildFieldLabel('Conferma password', textPurple),
                _buildTextField(
                  controller: _confirmPasswordController,
                  borderColor: _campiNonCompilati ? errorColor : defaultBorder,
                  obscureText: _obscureConfirmPassword,
                  hint: '••••••••',
                  errorText: _campiNonCompilati
                      ? 'Le password non coincidono *'
                      : null,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      child: Text(
                        _obscureConfirmPassword ? 'Mostra' : 'Nascondi',
                        style: const TextStyle(
                          color: Color(0xFF8A72D9),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30.0),

                // Pulsante Registrati
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: ElevatedButton(
                    onPressed: _registrati,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Registrati',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20.0),

                // Divisore
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: defaultBorder, thickness: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'oppure',
                        style: TextStyle(color: textGrey, fontSize: 14.0),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: defaultBorder, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 3.0),

                // Link Torna al Login
                Center(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pop(context, _emailController.text),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: textPurple, fontSize: 16.0),
                        children: [
                          TextSpan(text: 'Hai già un account? '),
                          TextSpan(
                            text: 'Accedi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 5.0),

                // Indicatori di pagina (Puntini)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(false, textGrey),
                    const SizedBox(width: 8),
                    _buildDot(true, textPurple),
                    const SizedBox(width: 8),
                    _buildDot(false, textGrey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required Color borderColor,
    String? hint,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF8A72D9), width: 1.5),
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 4.0),
            child: Text(
              errorText,
              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 11.0),
            ),
          ),
      ],
    );
  }

  Widget _buildDot(bool active, Color color) {
    return Container(
      width: active ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color : color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
