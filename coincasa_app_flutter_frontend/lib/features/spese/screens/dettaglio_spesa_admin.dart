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
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/spese/screens/elimina_spesa.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/features/spese/screens/modifica_spesa_admin.dart';

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
  bool _isPaying = false;

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

    final inquilini = results[2] as List<Inquilino>;
    final currentUser = _resolveCurrentUser(inquilini);

    return _SpesaDetailData(
      casa: casa,
      spesa: results[0] as Spesa,
      quote: results[1] as List<Quota>,
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
          _detailFuture = _loadDetailData();
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
            return _DetailContent(
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

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.data,
    required this.isPaying,
    required this.onPayQuota,
  });

  final _SpesaDetailData data;
  final bool isPaying;
  final ValueChanged<String> onPayQuota;

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

    final isCreator = data.spesa.isCreatedBy(data.currentUserId);
    final hasAnyPaidQuota = _computeHasAnyPaidQuota(data);
    final hasAnticipatore = _spesaHasAnticipatore(data.spesa.raw);
    final anticipatoreNome = hasAnticipatore ? data.spesa.creatoreNome : null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p25,
              AppSizes.p24,
              AppSizes.p25,
              AppSizes.p16,
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
          if (hasAnyPaidQuota) ...[
            const SizedBox(height: AppSizes.p16),
            const _LockedBanner(),
          ],
          const SizedBox(height: AppSizes.p24),
          _CreatorAvatarRow(creatoreNome: data.spesa.creatoreNome),
          const SizedBox(height: AppSizes.p24),
          _SummaryCard(
            payerNames: payerNames.isEmpty ? const ['Nessuno'] : payerNames,
            quotaPerPersona: quotaPerPersona,
            anticipatoreNome: anticipatoreNome,
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
          _QuoteStatusCard(
            rows: rows,
            isPaying: isPaying,
            onPayQuota: onPayQuota,
          ),
        ],
      ),
    ),
        ),
        DetailActionsBar(
          modifyLabel: 'Modifica spesa',
          deleteLabel: 'Elimina spesa',
          backLabel: 'Torna alle spese',
          isCreator: isCreator,
          onModify: hasAnyPaidQuota
              ? null
              : () => Navigator.of(context).pushNamed(
                    ModificaSpesaAdminScreen.routeName,
                    arguments: data.spesa,
                  ),
          onDelete: hasAnyPaidQuota
              ? null
              : () => Navigator.of(context).pushNamed(
                    EliminaSpesaScreen.routeName,
                    arguments: data.spesa.id,
                  ),
          onBack: () => Navigator.of(context)
              .pushReplacementNamed(ListaSpeseAdminScreen.routeName),
        ),
      ],
    );
  }

  bool _computeHasAnyPaidQuota(_SpesaDetailData data) {
    if (data.quote.isNotEmpty) {
      return data.quote.any((q) => q.pagata);
    }
    if (data.spesa.partecipanti.isNotEmpty) {
      return data.spesa.partecipanti.any(
        (p) =>
            p['pagato'] == true ||
            p['pagata'] == true ||
            p['saldato'] == true,
      );
    }
    return false;
  }

  List<_QuotaRowData> _buildRows(_SpesaDetailData data) {
    if (data.quote.isNotEmpty) {
      return data.quote.map((quota) {
        final inquilino = _inquilinoForQuota(quota, data.inquilini);
        final id = inquilino?.id ?? _quotaUserId(quota);
        final isCurrent = id.isNotEmpty && id == data.currentUserId;
        final name = _nameForQuota(quota, data.inquilini);
        return _QuotaRowData(
          name: isCurrent ? '$name (Tu)' : name,
          initials: _initials(name),
          isPaid: quota.pagata,
          isExcluded: false,
          isCurrentUser: isCurrent,
          quotaId: quota.id,
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

class _LockedBanner extends StatelessWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1800),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9E45), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.lock_rounded, color: Color(0xFFFF9E45), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Questa spesa ha quote già pagate: modifica ed eliminazione bloccate.',
              style: TextStyle(
                color: Color(0xFFFFBC6B),
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorAvatarRow extends StatelessWidget {
  const _CreatorAvatarRow({required this.creatoreNome});

  final String creatoreNome;

  @override
  Widget build(BuildContext context) {
    final nome = creatoreNome.trim();
    final initials = nome.isNotEmpty ? _initials(nome) : 'C';
    final firstName = nome.isNotEmpty
        ? nome.split(RegExp(r'\s+')).first
        : 'Coinquilino';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _avatarColor(initials),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Text(
          '$firstName ha creato questa spesa',
          style: const TextStyle(
            color: Color(0xFFAFAEAE),
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.payerNames,
    required this.quotaPerPersona,
    this.anticipatoreNome,
  });

  final List<String> payerNames;
  final double quotaPerPersona;
  final String? anticipatoreNome;

  @override
  Widget build(BuildContext context) {
    final hasAnticipatore =
        anticipatoreNome != null && anticipatoreNome!.trim().isNotEmpty;

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
            label: 'Chi ha anticipato',
            value: hasAnticipatore
                ? anticipatoreNome!.trim().split(RegExp(r'\s+')).first
                : '-',
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
  const _QuoteStatusCard({
    required this.rows,
    required this.isPaying,
    required this.onPayQuota,
  });

  final List<_QuotaRowData> rows;
  final bool isPaying;
  final ValueChanged<String> onPayQuota;

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
            _QuoteStatusRow(
              row: rows[index],
              isPaying: isPaying,
              onPayQuota: onPayQuota,
            ),
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
  const _QuoteStatusRow({
    required this.row,
    required this.isPaying,
    required this.onPayQuota,
  });

  final _QuotaRowData row;
  final bool isPaying;
  final ValueChanged<String> onPayQuota;

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

    final showPayButton = row.isCurrentUser && !row.isPaid && !row.isExcluded && row.quotaId != null;

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
    this.currentUserId,
  });

  final Casa casa;
  final Spesa spesa;
  final List<Quota> quote;
  final List<Inquilino> inquilini;
  final String? currentUserId;
}

class _QuotaRowData {
  const _QuotaRowData({
    required this.name,
    required this.initials,
    required this.isPaid,
    required this.isExcluded,
    this.isCurrentUser = false,
    this.quotaId,
  });

  final String name;
  final String initials;
  final bool isPaid;
  final bool isExcluded;
  final bool isCurrentUser;
  final String? quotaId;
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

String _displayName(Inquilino inquilino) {
  final fullName = inquilino.nomeCompleto.trim();
  if (fullName.isNotEmpty) return fullName;
  if (inquilino.username.trim().isNotEmpty) return inquilino.username.trim();
  return inquilino.email.trim().isEmpty ? 'Coinquilino' : inquilino.email;
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

bool _spesaHasAnticipatore(Map<String, dynamic> raw) {
  final anticipataDa = raw['anticipataDa'];
  if (anticipataDa != null && anticipataDa.toString().trim().isNotEmpty) {
    return true;
  }
  final pagatore = raw['pagatore'];
  if (pagatore is Map && pagatore.isNotEmpty) return true;
  if (pagatore is String && pagatore.trim().isNotEmpty) return true;
  final pagatoreNome = raw['pagatoreNome'] ?? raw['pagatoDa'];
  if (pagatoreNome != null && pagatoreNome.toString().trim().isNotEmpty) {
    return true;
  }
  return false;
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
