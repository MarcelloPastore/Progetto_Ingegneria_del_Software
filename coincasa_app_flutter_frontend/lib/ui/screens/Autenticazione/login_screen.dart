import 'package:flutter/material.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bool hasError =
        false; // Imposta a true per simulare un errore di login

    const Color primaryPurple = Color(0xFF4C2A9E);
    const Color textPurple = Color(0xFF8A72D9);
    const Color textGrey = Color(0xFF8C8C96);
    const Color defaultBorder = Color(0xFF3B3B54);

    // Colori per lo stato d'errore dedotti dal suo design
    const Color errorColor = Color(0xFFD32F2F);
    const Color errorBgColor = Color(0xFF3A0B0B);

    const Color BorderColor = hasError ? errorColor : textGrey;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF090616),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 28.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/Icons/home_auth_icon.png',
                  height: 110.0,
                  width: 110.0,
                  errorBuilder: (_, __, ___) => Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.home, size: 60, color: textPurple),
                  ),
                ),
                const SizedBox(height: 12.0),
                const Text(
                  'CoinCasa',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15.0),
                const Text(
                  'Bentornato!',
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),

                // Sostituzione dinamica del sottotitolo con il banner di errore
                if (hasError) ...[
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
                          color: errorColor,
                          size: 27.0,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            'Email o password non corretti.\nControlla i dati inseriti e riprova.',
                            style: TextStyle(
                              color: errorColor.withOpacity(0.9),
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
                  const SizedBox(height: 4.0),
                  const Text(
                    'Gestisci la convivenza senza stress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 35.0),
                ],

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: Color(0xFF996CFA),
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildTextField(
                      controller: _emailController,
                      borderColor: BorderColor,
                      hintText: 'marco@gmail.com',
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Password',
                      style: TextStyle(
                        color: Color(0xFF996CFA),
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildTextField(
                      borderColor: BorderColor,
                      obscureText: _obscurePassword,
                      hintText: '••••••••',
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 18.0,
                          ),
                          child: Text(
                            _obscurePassword ? 'Mostra' : 'Nascondi',
                            style: const TextStyle(
                              color: Color(0xFF996CFA),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 29.0),
                const Text(
                  'Password dimenticata?',
                  style: TextStyle(color: Color(0xFF996CFA), fontSize: 16.0),
                ),
                const SizedBox(height: 29.0),
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5228AD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accedi',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25.0),
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
                const SizedBox(height: 20.0),
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );

                    if (result != null &&
                        result is String &&
                        result.isNotEmpty) {
                      setState(() {
                        _emailController.text = result;
                      });
                    }
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: Color(0xFF996CFA),
                        fontSize: 16.0,
                      ),
                      children: [
                        TextSpan(text: 'Non hai un account?  '),
                        TextSpan(
                          text: 'Registrati',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
    required Color borderColor,
    bool obscureText = false,
    String? hintText,
    Widget? suffixIcon,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF8A72D9),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF8C8C96)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 18.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF8A72D9), width: 1.5),
        ),
      ),
    );
  }
}
