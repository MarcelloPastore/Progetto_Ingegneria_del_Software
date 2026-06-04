import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/inserisci_spesa_admin.dart';

class NessunaSpeseRegistrataScreen extends StatelessWidget {
  const NessunaSpeseRegistrataScreen({super.key});

  static const String routeName = '/spese/nessuna';

  Future<Casa?> _loadActiveCasa(BuildContext context) async {
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }
    return activeCasaController.resolveCasa(caseUtente);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF09051F),
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
        body: SafeArea(
          child: FutureBuilder<Casa?>(
            future: _loadActiveCasa(context),
            builder: (context, snapshot) {
              final casaNome = snapshot.data?.nome.trim().isNotEmpty == true
                  ? snapshot.data!.nome.trim()
                  : 'Casa';

              return SingleChildScrollView(
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
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Color(0xFFF6F6F6),
                        fontSize: 28,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p20),
                    Text(
                      casaNome,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Color(0xFF996CFA),
                        fontSize: 23,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Center(
                      child: Container(
                        width: 145,
                        height: 145,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2D9E6E).withValues(alpha: 0.1),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/Icons/carrello_spesa.png',
                          width: 100,
                          height: 100,
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
                        fontSize: 23,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p20),
                    const Text(
                      'Aggiungi la prima spesa della casa per\niniziare a dividere i costi con i\ncoinquilini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB1B1B1),
                        fontSize: 21,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p32),
                    ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(InserisciSpesaScreen.routeName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B2BC1),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.38),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.p16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius15,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Inserisci spesa',
                        style: TextStyle(
                          color: Color(0xFFF6F6F6),
                          fontSize: 23,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
