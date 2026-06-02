import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/icone_fab.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_admin.dart';
import 'package:coincasa_app/features/spese/screens/pareggia_conti.dart';

final _speseProvider = FutureProvider.autoDispose.family<List<Spesa>, String>((
  ref,
  casaId,
) async {
  return ApiProvider.spese.list(casaId);
});

final _saldiProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, casaId) async {
      final saldo = await ApiProvider.spese.getSaldo(casaId);
      final credito = await ApiProvider.spese.getCreditoTot(casaId);
      final debito = await ApiProvider.spese.getDebitoTot(casaId);

      return {'saldo': saldo, 'credito': credito, 'debito': debito};
    });

class ListaSpeseAdminScreen extends ConsumerStatefulWidget {
  const ListaSpeseAdminScreen({super.key});

  static const String routeName = '/spese/lista';

  @override
  ConsumerState<ListaSpeseAdminScreen> createState() =>
      _ListaSpeseAdminScreenState();
}

class _ListaSpeseAdminScreenState extends ConsumerState<ListaSpeseAdminScreen> {
  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.read(context);
    final selectedCasaId = activeCasaController.selectedCasaId;

    if (selectedCasaId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF151127),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final speseAsync = ref.watch(_speseProvider(selectedCasaId));
    final saldiAsync = ref.watch(_saldiProvider(selectedCasaId));
    final hasSpese = speseAsync.maybeWhen(
      data: (spese) => spese.isNotEmpty,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF151127),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: Stack(
          children: [
            speseAsync.when(
              data: (spese) {
                if (spese.isEmpty) {
                  return const _EmptyExpensesContent();
                }

                // Group spese by month
                final speseGroupedByMonth = <DateTime, List<Spesa>>{};
                for (final spesa in spese) {
                  final monthKey = DateTime(spesa.data.year, spesa.data.month);
                  speseGroupedByMonth.putIfAbsent(monthKey, () => []);
                  speseGroupedByMonth[monthKey]!.add(spesa);
                }

                // Sort months in reverse order
                final sortedMonths = speseGroupedByMonth.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 170),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Padding(
                        padding: EdgeInsets.only(top: AppSizes.p42),
                        child: Center(
                          child: Text(
                            'Spese',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.p24),

                      // Monthly balance card
                      saldiAsync.when(
                        data: (saldi) {
                          return _buildBalanceCard(saldi);
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSizes.p32),

                      // Spese list
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p22,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (
                              int monthIndex = 0;
                              monthIndex < sortedMonths.length;
                              monthIndex++
                            ) ...[
                              _buildMonthHeader(
                                sortedMonths[monthIndex],
                                isOpen: monthIndex == 0,
                              ),
                              const SizedBox(height: AppSizes.p16),
                              for (final spesa
                                  in speseGroupedByMonth[sortedMonths[monthIndex]]!)
                                _buildSpesaItem(context, spesa),
                              if (monthIndex < sortedMonths.length - 1)
                                const SizedBox(height: AppSizes.p24),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.p24),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Errore: $err')),
            ),

            if (hasSpese) _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFF151127),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p21,
          AppSizes.p20,
          AppSizes.p21,
          AppSizes.p18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(0.50, 0.00),
                    end: const Alignment(0.50, 1.00),
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: Color(0xFF4695EA),
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(PareggiaContiScreen.routeName),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius15),
                    ),
                  ),
                  child: const Text(
                    'Pareggia i conti',
                    style: TextStyle(
                      color: Color(0xFF4695EA),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const DashboardCreatePopup(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B45BA),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius15),
                  ),
                ),
                child: const Text(
                  'Inserisci una nuova spesa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, double> saldi) {
    final saldo = saldi['saldo'] ?? 0;
    final credito = saldi['credito'] ?? 0;
    final debito = saldi['debito'] ?? 0;

    final now = DateTime.now();
    final monthName = _getMonthName(now.month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p15),
      child: Container(
        decoration: ShapeDecoration(
          color: const Color(0xFF2C2846),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFF807D7D)),
            borderRadius: BorderRadius.circular(AppSizes.radius8),
          ),
          shadows: [
            BoxShadow(
              color: const Color(0x3F000000),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALDO MESE - $monthName ${now.year}',
                style: const TextStyle(
                  color: Color(0xFFAFAEAE),
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _BalanceMetric(
                        label: 'Totale mese',
                        value: '€${saldo.toStringAsFixed(0)}',
                        valueColor: const Color(0xFFE1E1E1),
                      ),
                    ),
                    const VerticalDivider(
                      color: Color(0xFFB8B5C1),
                      width: AppSizes.p18,
                      thickness: 1,
                    ),
                    Expanded(
                      child: _BalanceMetric(
                        label: 'Devi ricevere',
                        value: '€${credito.toStringAsFixed(0)}',
                        valueColor: const Color(0xFF47CC5D),
                      ),
                    ),
                    const VerticalDivider(
                      color: Color(0xFFB8B5C1),
                      width: AppSizes.p18,
                      thickness: 1,
                    ),
                    Expanded(
                      child: _BalanceMetric(
                        label: 'Devi pagare',
                        value: '€${debito.toStringAsFixed(0)}',
                        valueColor: const Color(0xFFF14A4A),
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

  Widget _buildMonthHeader(DateTime monthKey, {bool isOpen = false}) {
    return Opacity(
      opacity: isOpen ? 1.0 : 0.5,
      child: Text(
        '${_getMonthName(monthKey.month)} ${monthKey.year}${!isOpen ? ' (chiuso)' : ''}',
        style: const TextStyle(
          color: Color(0xFFAFAEAE),
          fontSize: 18,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSpesaItem(BuildContext context, Spesa spesa) {
    final initials = _getInitials(spesa.descrizione);
    final backgroundColor = _getAvatarColor(initials);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p16),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).pushNamed(DettaglioSpesaAdminScreen.routeName, arguments: spesa.id),
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 37,
                decoration: ShapeDecoration(
                  color: backgroundColor,
                  shape: const OvalBorder(),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: _getInitialsColor(initials),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spesa.descrizione,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      '${_formatDate(spesa.data)} - da pagare',
                      style: const TextStyle(
                        color: Color(0xFF908F8F),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '€${spesa.importo.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF908F8F),
                size: AppSizes.p20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String text) {
    return text.isNotEmpty ? text[0].toUpperCase() : 'S';
  }

  Color _getAvatarColor(String initials) {
    // Simple color assignment based on initial
    const colors = [
      Color(0xFFEE7274), // Red-ish
      Color(0xFF315173), // Blue-ish
      Color(0xFF584036), // Brown-ish
      Color(0xFF2D5E3F), // Green-ish
    ];

    final index = initials.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  Color _getInitialsColor(String initials) {
    if (initials == 'MR') {
      return const Color(0xFF2CFF64);
    } else if (initials == 'EM' || initials == 'E') {
      return const Color(0xFF5ACEF8);
    } else if (initials == 'GL') {
      return Colors.white;
    }
    return Colors.white;
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthShort(date.month)}';
  }

  String _getMonthName(int month) {
    const months = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];
    return months[month - 1];
  }

  String _getMonthShort(int month) {
    const months = [
      'gen',
      'feb',
      'mar',
      'apr',
      'mag',
      'giu',
      'lug',
      'ago',
      'set',
      'ott',
      'nov',
      'dic',
    ];
    return months[month - 1];
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 38,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFFAAA7B2),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: 23,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyExpensesContent extends StatelessWidget {
  const _EmptyExpensesContent();

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
    return FutureBuilder<Casa?>(
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
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const DashboardCreatePopup(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B2BC1),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.38),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius15),
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
    );
  }
}
