import 'package:flutter/material.dart';

class AccountActivatedScreen extends StatelessWidget {
  const AccountActivatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF5A2DB8);
    const Color buttonBorder = Color(0xFF9F91EA);
    const Color textGrey = Color(0xFFB0A9B8);

    return Scaffold(
      backgroundColor: const Color(0xFF090616),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 32.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.18),
                      Image.asset(
                        'assets/Icons/green_check_mark.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 58),
                      const Text(
                        'Account attivato!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'La tua email è stata verificata\ncon successo. Ora puoi\ncontinuare e creare la tua casa\ncondivisa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 20,
                          height: 1.18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: buttonBorder,
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Continua',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
