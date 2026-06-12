import 'package:flutter/material.dart';

import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_admin.dart';

class ModificheSpeseSuccessoScreen extends StatelessWidget {
  const ModificheSpeseSuccessoScreen({super.key});

  static const String routeName = '/spese/modifica-successo';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final spesa = args is Spesa ? args : null;

    return Scaffold(
      backgroundColor: const Color(0xFF6F6C78),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  border: Border.all(color: const Color(0xFF737373), width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('✓', style: TextStyle(fontSize: 100, height: 1)),
                    const SizedBox(height: 8),
                    const Text(
                      'Spesa Modificata!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Le modifiche alla spesa sono state salvate correttamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB8B5C1),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 42),
                    _SummaryTable(spesa: spesa),
                    const SizedBox(height: 84),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3C8B45),
                        border: Border.all(
                          color: const Color(0xFF42FF58),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'Tutti i coinquilini sono stati\nnotificati delle modifiche.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed(
                              DettaglioSpesaAdminScreen.routeName,
                              arguments: spesa?.id,
                            ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.brandPrimary,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius16,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Torna al Dettaglio spesa',
                          style: TextStyle(
                            color: AppColors.brandAccent,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.spesa});

  final Spesa? spesa;

  @override
  Widget build(BuildContext context) {
    final total = spesa?.importo ?? 60;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF807D7D), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          _TableRow(
            label: 'Descrizione',
            value: spesa?.descrizione ?? 'Spesa Supermercato',
          ),
          const Divider(color: Color(0xFF807D7D), height: 10),
          _TableRow(label: 'Totale', value: _formatCurrency(total)),
          const Divider(color: Color(0xFF807D7D), height: 10),
          const _TableRow(label: 'Ha pagato', value: 'Francesco'),
          const Divider(color: Color(0xFF807D7D), height: 10),
          _TableRow(
            label: 'Quota per persona',
            value: _formatCurrency(total / 4),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAFAEAE),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
    );
  }
}

String _formatCurrency(double value) {
  return '€ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
