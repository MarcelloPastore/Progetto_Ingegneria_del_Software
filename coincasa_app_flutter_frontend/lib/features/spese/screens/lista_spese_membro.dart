import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_debitore.dart';
import 'package:coincasa_app/features/spese/screens/inserisci_spesa_membro.dart';
import 'package:coincasa_app/features/spese/screens/pareggia_conti.dart';

final _memberSpeseDataProvider = FutureProvider.autoDispose
    .family<_MemberSpeseData?, String?>((ref, selectedCasaId) async {
      final caseUtente = await ApiProvider.casa.list();
      if (caseUtente.isEmpty) {
        return null;
      }
      final casa = _resolveCasa(caseUtente, selectedCasaId);
      final spese = await ApiProvider.spese.list(casa.id);
      final amounts = await Future.wait<double>([
        ApiProvider.spese.getSaldo(casa.id).catchError((_) => 0.0),
        ApiProvider.spese.getCreditoTot(casa.id).catchError((_) => 0.0),
        ApiProvider.spese.getDebitoTot(casa.id).catchError((_) => 0.0),
      ]);
      return _MemberSpeseData(
        casa: casa,
        spese: spese,
        totaleMese: spese.fold(0, (sum, spesa) => sum + spesa.importo),
        credito: amounts[1],
        debito: amounts[2],
      );
    });

class ListaSpeseMembroScreen extends ConsumerWidget {
  const ListaSpeseMembroScreen({super.key});

  static const String routeName = '/spese/membro';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCasaId = ActiveCasaScope.read(context).selectedCasaId;
    final asyncData = ref.watch(_memberSpeseDataProvider(selectedCasaId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF151127),
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
        body: SafeArea(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const _StateMessage(message: 'Dati non disponibili.'),
            data: (data) => data == null
                ? const _StateMessage(message: 'Nessuna casa disponibile.')
                : _MemberSpeseContent(data: data),
          ),
        ),
      ),
    );
  }
}

class _MemberSpeseContent extends StatelessWidget {
  const _MemberSpeseContent({required this.data});

  final _MemberSpeseData data;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByMonth(data.spese);
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 176),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF996CFA)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'Spese',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SummaryCard(data: data),
              const SizedBox(height: 25),
              for (final entry in groups.entries) ...[
                _MonthTitle(entry.key),
                const SizedBox(height: 8),
                for (int index = 0; index < entry.value.length; index++) ...[
                  _ExpenseTile(spesa: entry.value[index]),
                  if (index < entry.value.length - 1)
                    const Divider(height: 1, color: Color(0xFF77727F)),
                ],
                const SizedBox(height: 28),
              ],
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: Column(
            children: [
              if (data.spese.isNotEmpty) ...[
                _BlueOutlineButton(
                  label: 'Pareggia i conti',
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(PareggiaContiScreen.routeName),
                ),
                const SizedBox(height: 12),
              ],
              _PrimaryBlueButton(
                label: 'Inserisci una nuova spesa',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(InserisciSpesaMembroScreen.routeName),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _MemberSpeseData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF312B4A),
        border: Border.all(color: const Color(0xFF77727F), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'SALDO MESE - ${_monthName(DateTime.now().month).toUpperCase()} ${DateTime.now().year}',
            style: const TextStyle(
              color: Color(0xFFC1BFC8),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
          const Divider(color: Color(0xFF77727F), height: 22),
          Row(
            children: [
              _SummaryColumn(
                label: 'Totale mese',
                value: _formatCurrency(data.totaleMese),
                color: Colors.white,
              ),
              const _VerticalLine(),
              _SummaryColumn(
                label: 'Devi ricevere',
                value: _formatCurrency(data.credito),
                color: const Color(0xFF4DE45F),
              ),
              const _VerticalLine(),
              _SummaryColumn(
                label: 'Devi pagare',
                value: _formatCurrency(data.debito),
                color: const Color(0xFFFF5555),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF918D9A),
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.spesa});

  final Spesa spesa;

  @override
  Widget build(BuildContext context) {
    final creator = spesa.creatoreNome.isEmpty
        ? 'coinquilino'
        : spesa.creatoreNome;
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(DettaglioSpesaDebitoreScreen.routeName, arguments: spesa.id),
      child: Container(
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        color: Colors.transparent,
        child: Row(
          children: [
            _Avatar(initials: _initials(creator)),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spesa.descrizione.isEmpty ? 'Spesa' : spesa.descrizione,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${spesa.data.day} ${_monthShort(spesa.data.month)} - $creator ha pagato',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF918D9A),
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatCurrency(spesa.importo),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueOutlineButton extends StatelessWidget {
  const _BlueOutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
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
              color: Color(0xFF4796EA),
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
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4796EA),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBlueButton extends StatelessWidget {
  const _PrimaryBlueButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B58D5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFF8D8A92), width: 1.4),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _avatarColor(initials),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF70FF90),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MonthTitle extends StatelessWidget {
  const _MonthTitle(this.month);

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final closed = month.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month),
    );
    return Text(
      '${_monthName(month.month).toUpperCase()} ${month.year}${closed ? ' (chiuso)' : ''}',
      style: TextStyle(
        color: closed ? const Color(0xFF6F687C) : const Color(0xFFC1BFC8),
        fontSize: 17,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _VerticalLine extends StatelessWidget {
  const _VerticalLine();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 35, color: const Color(0xFF77727F));
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _MemberSpeseData {
  const _MemberSpeseData({
    required this.casa,
    required this.spese,
    required this.totaleMese,
    required this.credito,
    required this.debito,
  });

  final Casa casa;
  final List<Spesa> spese;
  final double totaleMese;
  final double credito;
  final double debito;
}

Casa _resolveCasa(List<Casa> caseUtente, String? selectedCasaId) {
  if (selectedCasaId != null) {
    for (final casa in caseUtente) {
      if (casa.id == selectedCasaId) {
        return casa;
      }
    }
  }
  return caseUtente.first;
}

Map<DateTime, List<Spesa>> _groupByMonth(List<Spesa> spese) {
  final grouped = <DateTime, List<Spesa>>{};
  for (final spesa in spese) {
    final key = DateTime(spesa.data.year, spesa.data.month);
    grouped.putIfAbsent(key, () => []).add(spesa);
  }
  for (final list in grouped.values) {
    list.sort((a, b) => b.data.compareTo(a.data));
  }
  final entries = grouped.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key));
  return Map.fromEntries(entries);
}

String _formatCurrency(double value) {
  return '€${value.toStringAsFixed(0)}';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'C';
  }
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

Color _avatarColor(String initials) {
  const colors = [
    Color(0xFF218D45),
    Color(0xFF2E6E9A),
    Color(0xFFEF6C73),
    Color(0xFF5D3D2F),
  ];
  return colors[initials.hashCode.abs() % colors.length];
}

String _monthName(int month) {
  const months = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];
  return months[month - 1];
}

String _monthShort(int month) {
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
