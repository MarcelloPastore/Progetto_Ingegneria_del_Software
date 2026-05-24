import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CheckEmailScreen extends StatelessWidget {
  final String email;

  const CheckEmailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    const Color textPurple = Color(0xFF996CFA);
    const Color textGrey = Color(0xFF8C8C96);

    return Scaffold(
      backgroundColor: const Color(0xFF090616),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),

                        SvgPicture.asset(
                          'assets/Icons/check_email.svg',
                          width: 100,
                          height: 100,
                          placeholderBuilder: (context) =>
                              const SizedBox(width: 100, height: 100),
                        ),

                        const SizedBox(height: 32),

                        // Titolo
                        const Text(
                          'Controlla la tua mail!',
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sottotitolo
                        const Text(
                          'Abbiamo inviato un link di verifica a:',
                          style: TextStyle(fontSize: 16.0, color: textGrey),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Box email
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151528),
                            border: Border.all(color: textPurple, width: 1.5),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500,
                              color: textPurple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Testo di istruzioni
                        const Text(
                          "Clicca sul link nell'email per\nattivare il tuo account.\nPotrebbe richiedere qualche\nminuto.",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: textGrey,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(),

                        // Link reinvia email
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 16.0,
                            ),
                            children: [
                              const TextSpan(
                                text: "Non hai ricevuto l'email? ",
                              ),
                              TextSpan(
                                text: 'Reinvia',
                                style: const TextStyle(
                                  color: textPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Logica di reinvio email
                                  },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Link modifica email
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 16.0,
                            ),
                            children: [
                              const TextSpan(text: "Email sbagliata? "),
                              TextSpan(
                                text: 'Modifica',
                                style: const TextStyle(
                                  color: textPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pop(context);
                                  },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
