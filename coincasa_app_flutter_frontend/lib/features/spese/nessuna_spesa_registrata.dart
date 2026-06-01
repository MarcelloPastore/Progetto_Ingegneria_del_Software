import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';

class NessunaSpeseRegistrataScreen extends StatelessWidget {
  const NessunaSpeseRegistrataScreen({super.key});

  static const String routeName = '/spese/nessuna';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09051F),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p25,
            AppSizes.p32,
            AppSizes.p25,
            AppSizes.p32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Spese',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF6F6F6),
                  fontSize: 24,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p68),
              Center(
                child: Container(
                  width: 135,
                  height: 135,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2D9E6E).withValues(alpha: 0.1),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/Icons/carrello_spesa.png',
                    width: 82,
                    height: 82,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p24),
              const Text(
                'Nessuna spesa registrata',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF6F6F6),
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              const SizedBox(
                width: 337,
                child: Text(
                  'Aggiungi la prima spesa della casa per\niniziare a dividere i costi con i coinquilini',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB1B1B1),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p56),
              Center(
                child: SizedBox(
                  width: 337,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/spese/nuovo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5228AD),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.p16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius15),
                      ),
                    ),
                    child: const Text(
                      'Aggiungi spesa',
                      style: TextStyle(
                        color: Color(0xFFF2ECFF),
                        fontSize: 20,
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
    );
  }
}
