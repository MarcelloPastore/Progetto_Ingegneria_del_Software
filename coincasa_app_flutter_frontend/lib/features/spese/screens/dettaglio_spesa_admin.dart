import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/elimina_spesa.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/features/spese/screens/modifiche_spese_negata.dart';

class DettaglioSpesaAdminScreen extends ConsumerStatefulWidget {
  const DettaglioSpesaAdminScreen({super.key});

  static const String routeName = '/spese/dettaglio-admin';

  @override
  ConsumerState<DettaglioSpesaAdminScreen> createState() =>
      _DettaglioSpesaAdminScreenState();
}

class _DettaglioSpesaAdminScreenState
    extends ConsumerState<DettaglioSpesaAdminScreen> {
  late Future<_SpesaDetailData?> _detailFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _detailFuture = _loadDetailData();
  }

  Future<_SpesaDetailData?> _loadDetailData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }

    final casa = activeCasaController.resolveCasa(caseUtente);
    final argSpesa = args is Spesa ? args : null;
    final spesaId = argSpesa?.id ?? (args is String ? args : null);
    if (spesaId == null || spesaId.isEmpty) {
      return null;
    }

    final results = await Future.wait<dynamic>([
      argSpesa == null
          ? ApiProvider.spese.getById(casa.id, spesaId)
          : Future<Spesa>.value(argSpesa),
      ApiProvider.spese
          .getQuote(casa.id, spesaId)
          .catchError((_) => const <Quota>[]),
      ApiProvider.casa
          .listInquilini(casa.id)
          .catchError((_) => const <Inquilino>[]),
    ]);

    return _SpesaDetailData(
      casa: casa,
      spesa: results[0] as Spesa,
      quote: results[1] as List<Quota>,
      inquilini: results[2] as List<Inquilino>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151127),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: FutureBuilder<_SpesaDetailData?>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const _DetailState(message: 'Spesa non disponibile.');
            }
            return _DetailContent(data: data);
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.data});

  final _SpesaDetailData data;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(data);
    final payerNames = rows
        .where((row) => !row.isExcluded && !row.isPaid)
        .map((row) => row.name)
        .toList();
    final includedRows = rows.where((row) => !row.isExcluded).length;
    final quotaPerPersona = includedRows == 0
        ? data.spesa.importo
        : data.spesa.importo / includedRows;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p25,
        AppSizes.p24,
        AppSizes.p25,
        AppSizes.p32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.brandAccent,
                  size: AppSizes.p28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSizes.p32,
                  minHeight: AppSizes.p32,
                ),
              ),
              const SizedBox(width: AppSizes.p6),
              Text(
                'Dettaglio spesa',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.brandAccent,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p48),
          Text(
            _formatCurrency(data.spesa.importo),
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong.copyWith(
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p6),
          Text(
            '${data.spesa.descrizione} - ${_formatLongDate(data.spesa.data)}',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong.copyWith(
              color: const Color(0xFFAFAEAE),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppSizes.p32),
          _SummaryCard(
            payerNames: payerNames.isEmpty ? const ['Nessuno'] : payerNames,
            quotaPerPersona: quotaPerPersona,
          ),
          const SizedBox(height: AppSizes.p32),
          Text(
            'STATO QUOTE',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: const Color(0xFFC1BFC8),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p10),
          _QuoteStatusCard(rows: rows),
          const SizedBox(height: AppSizes.p56),
          Row(
            children: [
              Expanded(
                child: _OutlinedActionButton(
                  label: 'Modifica spesa',
                  color: AppColors.brandAccent,
                  onPressed: () => Navigator.of(context).pushNamed(
                    ModificheSpeseNegataScreen.routeName,
                    arguments: data.spesa.id,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: _OutlinedActionButton(
                  label: 'Elimina spesa',
                  color: const Color(0xFFF14A4A),
                  onPressed: () => Navigator.of(context).pushNamed(
                    EliminaSpesaScreen.routeName,
                    arguments: data.spesa.id,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).pushReplacementNamed(ListaSpeseAdminScreen.routeName),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B45BA),
                padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius15),
                ),
              ),
              child: const Text(
                'Torna alle spese',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_QuotaRowData> _buildRows(_SpesaDetailData data) {
    if (data.quote.isNotEmpty) {
      return data.quote.map((quota) {
        final name = _nameForQuota(quota, data.inquilini);
        return _QuotaRowData(
          name: name,
          initials: _initials(name),
          isPaid: quota.pagata,
          isExcluded: false,
        );
      }).toList();
    }

    if (data.spesa.partecipanti.isNotEmpty) {
      return data.spesa.partecipanti.map((partecipante) {
        final name = _nameForPartecipante(partecipante);
        final excluded = partecipante['escluso'] == true;
        final paid =
            partecipante['pagato'] == true ||
            partecipante['pagata'] == true ||
            partecipante['saldato'] == true;
        return _QuotaRowData(
          name: name,
          initials: _initials(name),
          isPaid: paid,
          isExcluded: excluded,
        );
      }).toList();
    }

    return const [];
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.payerNames, required this.quotaPerPersona});

  final List<String> payerNames;
  final double quotaPerPersona;

  @override
  Widget build(BuildContext context) {
    // Estrae solo il primo nome per ogni elemento nella lista dei pagatori
    final firstNamesOnly = payerNames.map((name) {
      return name.trim().split(RegExp(r'\s+')).first;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A2D),
        border: Border.all(color: const Color(0xFF807D7D), width: 1.2),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p18,
        AppSizes.p20,
        AppSizes.p18,
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Chi deve pagare',
            value: firstNamesOnly.join(', '),
          ),
          const Divider(color: Color(0xFF716E76), height: AppSizes.p18),
          _SummaryRow(
            label: 'Quota per persone',
            value: _formatCurrency(quotaPerPersona),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(
              color: const Color(0xFFAFAEAE),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textOnDark,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuoteStatusCard extends StatelessWidget {
  const _QuoteStatusCard({required this.rows});

  final List<_QuotaRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A2D),
        border: Border.all(color: const Color(0xFF807D7D), width: 1.4),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p15,
        vertical: AppSizes.p16,
      ),
      child: Column(
        children: [
          for (int index = 0; index < rows.length; index++) ...[
            _QuoteStatusRow(row: rows[index]),
            if (index < rows.length - 1)
              const Divider(
                color: Color(0xFF5D5964),
                height: AppSizes.p20,
                indent: AppSizes.p58,
              ),
          ],
        ],
      ),
    );
  }
}

class _QuoteStatusRow extends StatelessWidget {
  const _QuoteStatusRow({required this.row});

  final _QuotaRowData row;

  @override
  Widget build(BuildContext context) {
    final muted = row.isExcluded;
    final status = row.isExcluded
        ? 'escluso/a'
        : row.isPaid
        ? 'Pagato'
        : 'Da pagare';
    final statusColor = row.isExcluded
        ? const Color(0xFFAFAEAE)
        : row.isPaid
        ? const Color(0xFF2CFF64)
        : const Color(0xFFFF6767);

    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _avatarColor(
              row.initials,
            ).withValues(alpha: muted ? 0.38 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            row.initials,
            style: TextStyle(
              color: muted ? const Color(0xFFB8844D) : Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p16),
        Expanded(
          child: Text(
            row.name,
            style: TextStyle(
              color: muted ? const Color(0xFFAFAEAE) : Colors.white,
              fontSize: 19,
              fontFamily: 'Inter',
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontSize: 18,
            fontFamily: 'Inter',
            fontStyle: muted ? FontStyle.italic : FontStyle.normal,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF151127),
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailState extends StatelessWidget {
  const _DetailState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _SpesaDetailData {
  const _SpesaDetailData({
    required this.casa,
    required this.spesa,
    required this.quote,
    required this.inquilini,
  });

  final Casa casa;
  final Spesa spesa;
  final List<Quota> quote;
  final List<Inquilino> inquilini;
}

class _QuotaRowData {
  const _QuotaRowData({
    required this.name,
    required this.initials,
    required this.isPaid,
    required this.isExcluded,
  });

  final String name;
  final String initials;
  final bool isPaid;
  final bool isExcluded;
}

String _nameForQuota(Quota quota, List<Inquilino> inquilini) {
  final raw = quota.raw;
  final id =
      raw['inquilinoId'] ??
      raw['idInquilino'] ??
      raw['utenteId'] ??
      raw['idUtente'] ??
      raw['userId'] ??
      (raw['utente'] is Map ? raw['utente']['id'] : null);
  if (id != null) {
    for (final inquilino in inquilini) {
      if (inquilino.id == id.toString()) {
        return inquilino.nomeCompleto.isEmpty
            ? inquilino.email
            : inquilino.nomeCompleto;
      }
    }
  }
  return raw['nome']?.toString() ??
      raw['name']?.toString() ??
      raw['username']?.toString() ??
      (raw['utente'] is Map ? raw['utente']['username']?.toString() : null) ??
      'Coinquilino';
}

String _nameForPartecipante(Map<String, dynamic> partecipante) {
  final utente = partecipante['utente'];
  if (utente is Map) {
    final nome =
        utente['nome'] ??
        utente['name'] ??
        utente['username'] ??
        utente['email'];
    if (nome != null && nome.toString().trim().isNotEmpty) {
      return nome.toString();
    }
  }
  return partecipante['nome']?.toString() ??
      partecipante['name']?.toString() ??
      partecipante['username']?.toString() ??
      'Coinquilino';
}

String _initials(String name) {
  final parts = name
      .replaceAll('(Tu)', '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'C';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

Color _avatarColor(String initials) {
  const colors = [
    Color(0xFF17A832),
    Color(0xFFEE7274),
    Color(0xFF315173),
    Color(0xFF584036),
    Color(0xFF2D5E3F),
  ];
  return colors[initials.codeUnitAt(0) % colors.length];
}

String _formatCurrency(double value) {
  return '€${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatLongDate(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
