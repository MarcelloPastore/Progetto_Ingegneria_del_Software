import 'package:flutter/material.dart';

import 'package:coincasa_app/core/utils/formatters.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/coinquilini_notified_banner.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/ui/spese/screens/dettaglio_spesa.dart';

class ModificheSpeseSuccessoScreen extends StatelessWidget {
  const ModificheSpeseSuccessoScreen({super.key});

  static const String routeName = '/spese/modifica-successo';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final spesa = args is Spesa ? args : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p20,
            AppSizes.p40,
            AppSizes.p20,
            AppSizes.p28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p16,
                  AppSizes.p14,
                  AppSizes.p16,
                  AppSizes.p26,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  border: Border.all(
                    color: AppColors.textMutedDark,
                    width: AppSizes.p2,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radius10),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: AppSizes.p5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '✓',
                      style: TextStyle(
                        fontSize: AppSizes.p100,
                        height: AppSizes.p1,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p8),
                    const Text(
                      'Spesa Modificata!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: AppSizes.p25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p22),
                    const Text(
                      'Le modifiche alla spesa sono state salvate correttamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMutedSoft,
                        fontSize: AppSizes.p18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p42),
                    _SummaryTable(spesa: spesa),
                    const SizedBox(height: AppSizes.p84),
                    const CoinquiliniNotifiedBanner(
                      message:
                          'Tutti i coinquilini sono stati notificati delle modifiche.',
                    ),
                    const SizedBox(height: AppSizes.p26),
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
                            width: AppSizes.p2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.p16,
                          ),
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
                            fontSize: AppSizes.p21,
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
        border: Border.all(color: AppColors.borderMuted, width: AppSizes.p2),
        borderRadius: BorderRadius.circular(AppSizes.radius10),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p8,
      ),
      child: Column(
        children: [
          _TableRow(
            label: 'Descrizione',
            value: spesa?.descrizione ?? 'Spesa Supermercato',
          ),
          const Divider(color: AppColors.borderMuted, height: AppSizes.p10),
          _TableRow(label: 'Totale', value: formatCurrency(total)),
          const Divider(color: AppColors.borderMuted, height: AppSizes.p10),
          const _TableRow(label: 'Ha pagato', value: 'Francesco'),
          const Divider(color: AppColors.borderMuted, height: AppSizes.p10),
          _TableRow(
            label: 'Quota per persona',
            value: formatCurrency(total / 4),
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
              color: AppColors.textSubtle,
              fontSize: AppSizes.p15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: AppSizes.p15,
          ),
        ),
      ],
    );
  }
}
