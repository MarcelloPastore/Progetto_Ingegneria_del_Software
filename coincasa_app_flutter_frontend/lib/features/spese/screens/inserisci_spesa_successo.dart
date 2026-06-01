import 'package:flutter/material.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';

class InserisciSpesaSuccessoScreen extends StatelessWidget {
  const InserisciSpesaSuccessoScreen({super.key});

  static const String routeName = '/spese/successo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Semi-transparent background overlay
          Opacity(
            opacity: 0.50,
            child: Container(
              width: 403,
              height: 848,
              color: const Color(0xFFD9D9D9),
            ),
          ),

          // Success dialog container
          Center(
            child: SafeArea(
              child: Container(
                width: 303,
                height: 424,
                decoration: ShapeDecoration(
                  color: const Color(0xFF151127),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 3, color: Color(0xFF737373)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Checkmark icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF39B54A),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Success title
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Spesa aggiunta!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'La spesa è stata aggiunta. I coinquilini sono stati notificati',
                        style: TextStyle(
                          color: Color(0xFFB1B1B1),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Back to spese button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pushReplacementNamed(
                                ListaSpeseAdminScreen.routeName,
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4695EA),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Torna alle spese',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
