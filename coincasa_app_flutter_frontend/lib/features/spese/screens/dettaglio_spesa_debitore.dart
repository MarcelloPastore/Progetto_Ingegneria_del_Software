import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/elimina_spesa.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_membro.dart';
import 'package:coincasa_app/features/spese/screens/modifiche_spese_negata.dart';

class DettaglioSpesaDebitoreScreen extends StatefulWidget {
  const DettaglioSpesaDebitoreScreen({super.key});

  static const String routeName = '/spese/dettaglio-debitore';

  @override
  State<DettaglioSpesaDebitoreScreen> createState() =>
      _DettaglioSpesaDebitoreScreenState();
}

class _DettaglioSpesaDebitoreScreenState
    extends State<DettaglioSpesaDebitoreScreen> {
  Future<_DebtorDetailData?>? _future;
  bool _isPaying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _loadData();
  }

  Future<_DebtorDetailData?> _loadData() async {
    final spesaId = ModalRoute.of(context)?.settings.arguments?.toString();
    if (spesaId == null || spesaId.isEmpty) {
      return null;
    }
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }
    final casa = activeCasaController.resolveCasa(caseUtente);
    final spesa = await ApiProvider.spese.getById(casa.id, spesaId);
    final results = await Future.wait<dynamic>([
      ApiProvider.spese
          .getQuote(casa.id, spesa.id)
          .catchError((_) => <Quota>[]),
      ApiProvider.casa.listInquilini(casa.id).catchError((_) => <Inquilino>[]),
    ]);
    final inquilini = results[1] as List<Inquilino>;
    final currentUser = _resolveCurrentUser(inquilini);
    return _DebtorDetailData(
      casa: casa,
      spesa: spesa,
      quote: results[0] as List<Quota>,
      inquilini: inquilini,
      currentUserId: currentUser?.id,
    );
  }

  Future<void> _payQuota(String casaId, String spesaId, String quotaId) async {
    if (_isPaying) return;
    setState(() {
      _isPaying = true;
    });
    try {
      await ApiProvider.spese.pagaQuota(casaId, spesaId, quotaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quota pagata con successo!')),
        );
        setState(() {
          _future = _loadData();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile pagare la quota. Riprova.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151127),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: FutureBuilder<_DebtorDetailData?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(
                child: Text(
                  'Dettaglio non disponibile.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return _DebtorDetailContent(
              data: data,
              isPaying: _isPaying,
              onPayQuota: (quotaId) => _payQuota(data.casa.id, data.spesa.id, quotaId),
            );
          },
        ),
      ),
    );
  }
}

class _DebtorDetailContent extends StatelessWidget {
  const _DebtorDetailContent({
    required this.data,
    required this.isPaying,
    required this.onPayQuota,
  });

  final _DebtorDetailData data;
  final bool isPaying;
  final ValueChanged<String> onPayQuota;

  @override
  Widget build(BuildContext context) {
    final canManage = data.spesa.isCreatedBy(data.currentUserId);
    final payingNames = _payingNames(data);
    final quota = data.quote.isEmpty ? 0.0 : data.quote.first.importo;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 14, 21, 34),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical -
              103,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF996CFA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Dettaglio spesa',
                  style: TextStyle(
                    color: Color(0xFF996CFA),
                    fontSize: 19,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text(
              _formatCurrency(data.spesa.importo),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${data.spesa.descrizione} - ${_formatLongDate(data.spesa.data)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF918D9A),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _InfoBox(payingNames: payingNames, quota: quota),
            const SizedBox(height: 26),
            const Text(
              'STATO QUOTE',
              style: TextStyle(
                color: Color(0xFFC1BFC8),
                fontSize: 17,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _QuotesBox(
              data: data,
              isPaying: isPaying,
              onPayQuota: onPayQuota,
            ),
            if (canManage) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SmallManageButton(
                      label: 'Modifica',
                      onPressed: () => Navigator.of(context).pushNamed(
                        ModificheSpeseNegataScreen.routeName,
                        arguments: data.spesa.id,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallManageButton(
                      label: 'Elimina',
                      onPressed: () => Navigator.of(context).pushNamed(
                        EliminaSpesaScreen.routeName,
                        arguments: data.spesa.id,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            const SizedBox(height: 70),
            _PrimaryBlueButton(
              label: 'Torna alle spese',
              onPressed: () => Navigator.of(
                context,
              ).pushReplacementNamed(ListaSpeseMembroScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.payingNames, required this.quota});

  final String payingNames;
  final double quota;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF211C35),
        border: Border.all(color: const Color(0xFF77727F), width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Chi deve pagare', value: payingNames),
          const Divider(height: 12, color: Color(0xFF77727F)),
          _InfoRow(label: 'Quota per persone', value: _formatCurrency(quota)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

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
              color: Color(0xFF918D9A),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuotesBox extends StatelessWidget {
  const _QuotesBox({
    required this.data,
    required this.isPaying,
    required this.onPayQuota,
  });

  final _DebtorDetailData data;
  final bool isPaying;
  final ValueChanged<String> onPayQuota;

  @override
  Widget build(BuildContext context) {
    final rows = _quoteRows(data);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF211C35),
        border: Border.all(color: const Color(0xFF77727F), width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          for (int index = 0; index < rows.length; index++) ...[
            _QuoteTile(
              row: rows[index],
              isPaying: isPaying,
              onPayQuota: onPayQuota,
            ),
            if (index < rows.length - 1)
              const Divider(height: 1, color: Color(0xFF77727F)),
          ],
        ],
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({
    required this.row,
    required this.isPaying,
    required this.onPayQuota,
  });

  final _QuoteRow row;
  final bool isPaying;
  final ValueChanged<String> onPayQuota;

  @override
  Widget build(BuildContext context) {
    final showPayButton = row.isCurrentUser && !row.excluded && row.quotaId != null && row.status == 'Da pagare';

    return Container(
      height: 47,
      color: row.isCurrentUser ? const Color(0xFF8B8993) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          _Avatar(initials: row.initials, excluded: row.excluded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.name,
              style: TextStyle(
                color: row.excluded
                    ? const Color(0xFF8D8797)
                    : Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontStyle: row.excluded ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showPayButton)
            if (isPaying)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.lockOrange),
                ),
              )
            else
              SizedBox(
                height: 34,
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
                        color: AppColors.lockOrange,
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                    onPressed: () => onPayQuota(row.quotaId!),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Paga',
                      style: TextStyle(
                        color: AppColors.lockOrange,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
          else
            Text(
              row.status,
              style: TextStyle(
                color: row.statusColor,
                fontSize: 15,
                fontFamily: 'Inter',
                fontStyle: row.excluded ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.excluded});

  final String initials;
  final bool excluded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: excluded ? const Color(0xFF4A342E) : _avatarColor(initials),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: excluded ? const Color(0xFF6B4A28) : const Color(0xFF70FF90),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallManageButton extends StatelessWidget {
  const _SmallManageButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF996CFA)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF996CFA))),
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
      height: 49,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B58D5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF8D8A92), width: 1.3),
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

class _DebtorDetailData {
  const _DebtorDetailData({
    required this.casa,
    required this.spesa,
    required this.quote,
    required this.inquilini,
    required this.currentUserId,
  });

  final Casa casa;
  final Spesa spesa;
  final List<Quota> quote;
  final List<Inquilino> inquilini;
  final String? currentUserId;
}

class _QuoteRow {
  const _QuoteRow({
    required this.name,
    required this.initials,
    required this.status,
    required this.statusColor,
    required this.isCurrentUser,
    required this.excluded,
    this.quotaId,
  });

  final String name;
  final String initials;
  final String status;
  final Color statusColor;
  final bool isCurrentUser;
  final bool excluded;
  final String? quotaId;
}

List<_QuoteRow> _quoteRows(_DebtorDetailData data) {
  final includedIds = <String>{};
  final rows = <_QuoteRow>[];
  for (final quota in data.quote) {
    final inquilino = _inquilinoForQuota(quota, data.inquilini);
    final id = inquilino?.id ?? _quotaUserId(quota);
    if (id.isNotEmpty) {
      includedIds.add(id);
    }
    final name = _nameForQuota(quota, data.inquilini);
    final isCurrent = id.isNotEmpty && id == data.currentUserId;
    rows.add(
      _QuoteRow(
        name: isCurrent ? '$name (Tu)' : name,
        initials: _initials(name),
        status: quota.pagata ? 'Pagato' : 'Da pagare',
        statusColor: quota.pagata
            ? const Color(0xFF3DFF65)
            : const Color(0xFFFF7A7A),
        isCurrentUser: isCurrent,
        excluded: false,
        quotaId: quota.id,
      ),
    );
  }

  for (final inquilino in data.inquilini) {
    if (includedIds.contains(inquilino.id)) {
      continue;
    }
    final name = _displayName(inquilino);
    rows.add(
      _QuoteRow(
        name: name,
        initials: _initials(name),
        status: 'escluso/a',
        statusColor: const Color(0xFF8D8797),
        isCurrentUser: false,
        excluded: true,
      ),
    );
  }
  return rows;
}

String _payingNames(_DebtorDetailData data) {
  final names = data.quote
      .where((quota) => !quota.pagata)
      .map((quota) => _nameForQuota(quota, data.inquilini))
      .toList();
  if (names.isEmpty) {
    return 'Nessuno';
  }
  return names.join(', ');
}

Inquilino? _resolveCurrentUser(List<Inquilino> inquilini) {
  final email = ApiProvider.client.currentUserEmail?.trim().toLowerCase();
  final name = ApiProvider.client.currentUserName?.trim().toLowerCase();
  for (final inquilino in inquilini) {
    final values = [
      inquilino.email,
      inquilino.username,
      inquilino.nome,
      inquilino.nomeCompleto,
    ].map((value) => value.trim().toLowerCase());
    if ((email != null && values.contains(email)) ||
        (name != null && values.contains(name))) {
      return inquilino;
    }
  }
  return inquilini.isNotEmpty ? inquilini.first : null;
}

Inquilino? _inquilinoForQuota(Quota quota, List<Inquilino> inquilini) {
  final id = _quotaUserId(quota);
  for (final inquilino in inquilini) {
    if (inquilino.id == id) {
      return inquilino;
    }
  }
  return null;
}

String _quotaUserId(Quota quota) {
  final raw = quota.raw;
  final id =
      raw['inquilinoId'] ??
      raw['idInquilino'] ??
      raw['utenteId'] ??
      raw['idUtente'] ??
      raw['userId'] ??
      (raw['utente'] is Map ? raw['utente']['id'] : null);
  return id?.toString() ?? '';
}

String _nameForQuota(Quota quota, List<Inquilino> inquilini) {
  final inquilino = _inquilinoForQuota(quota, inquilini);
  if (inquilino != null) {
    return _displayName(inquilino);
  }
  final raw = quota.raw;
  return raw['nome']?.toString() ??
      raw['name']?.toString() ??
      raw['username']?.toString() ??
      (raw['utente'] is Map ? raw['utente']['username']?.toString() : null) ??
      'Coinquilino';
}

String _displayName(Inquilino inquilino) {
  final fullName = inquilino.nomeCompleto.trim();
  if (fullName.isNotEmpty) return fullName;
  if (inquilino.username.trim().isNotEmpty) return inquilino.username.trim();
  return inquilino.email.trim().isEmpty ? 'Coinquilino' : inquilino.email;
}

String _formatCurrency(double value) {
  return '€${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatLongDate(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _initials(String name) {
  final parts = name
      .replaceAll('(Tu)', '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
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
  return colors[initials.hashCode.abs() % colors.length];
}
