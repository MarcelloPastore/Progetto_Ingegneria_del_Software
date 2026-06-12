import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';

class PareggiaContiScreen extends ConsumerStatefulWidget {
  const PareggiaContiScreen({super.key});

  static const String routeName = '/spese/pareggia-conti';

  @override
  ConsumerState<PareggiaContiScreen> createState() =>
      _PareggiaContiScreenState();
}

class _PareggiaContiScreenState extends ConsumerState<PareggiaContiScreen> {
  late Future<_PareggiaData?> _future;
  bool _initialized = false;
  String? _submittingKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _loadData();
  }

  Future<_PareggiaData?> _loadData() async {
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) return null;

    final casa = activeCasaController.resolveCasa(caseUtente);
    final inquilini = await ApiProvider.casa.listInquilini(casa.id);
    final balances = <_BalanceRow>[];

    for (final inquilino in inquilini) {
      final isMe = _isCurrentUser(inquilino);
      double credito = 0;
      double debito = 0;
      if (!isMe) {
        final results = await Future.wait<double>([
          ApiProvider.spese
              .getCreditoVerso(casa.id, inquilino.id)
              .catchError((_) => 0.0),
          ApiProvider.spese
              .getDebitoVerso(casa.id, inquilino.id)
              .catchError((_) => 0.0),
        ]);
        credito = results[0]; // questa persona mi deve soldi
        debito = results[1];  // devo soldi a questa persona
      }
      balances.add(
        _BalanceRow(
          id: inquilino.id,
          name: _displayName(inquilino),
          initials: _initials(_displayName(inquilino)),
          credito: credito,
          debito: debito,
          isCurrentUser: isMe,
        ),
      );
    }

    // Saldo aggregato dell'utente corrente: somma di tutti i saldi netti
    final aggregateSaldo =
        balances.where((r) => !r.isCurrentUser).fold<double>(
          0,
          (sum, r) => sum + r.saldo,
        );
    final idx = balances.indexWhere((r) => r.isCurrentUser);
    if (idx != -1) {
      final me = balances[idx];
      balances[idx] = _BalanceRow(
        id: me.id,
        name: me.name,
        initials: me.initials,
        credito: aggregateSaldo > 0 ? aggregateSaldo : 0,
        debito: aggregateSaldo < 0 ? aggregateSaldo.abs() : 0,
        isCurrentUser: true,
      );
    }

    balances.sort((a, b) {
      // Utente corrente sempre PRIMO
      if (a.isCurrentUser) return -1;
      if (b.isCurrentUser) return 1;
      return a.name.compareTo(b.name);
    });

    final currentUserRow =
        balances.where((r) => r.isCurrentUser).firstOrNull;
    final currentUserName = currentUserRow?.name ?? 'Tu';
    final currentUserInitials = currentUserRow?.initials ?? 'T';

    final transfers = balances
        .where((r) => !r.isCurrentUser && r.debito > r.credito + 0.01)
        .map(
          (r) => _TransferRow(
            creditorId: r.id,
            creditorName: r.name,
            creditorInitials: r.initials,
            debtorName: currentUserName,
            debtorInitials: currentUserInitials,
            amount: r.debito,
          ),
        )
        .toList();

    return _PareggiaData(
      casa: casa,
      balances: balances,
      transfers: transfers,
    );
  }

  Future<void> _settleDebt(String creditorId, String creditorName) async {
    if (_submittingKey != null) return;
    setState(() => _submittingKey = creditorId);
    try {
      final data = await _future;
      if (data == null) return;
      await ApiProvider.spese.pareggia(data.casa.id, [creditorId]);
      if (!mounted) return;
      setState(() {
        _future = _loadData();
        _submittingKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debito verso $creditorName saldato!')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _submittingKey = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile saldare il debito. Riprova.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151127),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<_PareggiaData?>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data;
                  if (data == null) {
                    return const Center(
                      child: Text(
                        'Dati non disponibili.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return _PareggiaContent(
                    data: data,
                    submittingKey: _submittingKey,
                    onSettleDebt: _settleDebt,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: MainCtaButton(
                label: 'Torna alle spese',
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(ListaSpeseAdminScreen.routeName),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

class _PareggiaContent extends StatelessWidget {
  const _PareggiaContent({
    required this.data,
    required this.submittingKey,
    required this.onSettleDebt,
  });

  final _PareggiaData data;
  final String? submittingKey;
  final Future<void> Function(String creditorId, String creditorName)
      onSettleDebt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.brandAccent,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 6),
              Text(
                'Spese',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.brandAccent,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pareggia i conti',
            style: AppTextStyles.screenTitleStrong.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentMonthYear()} · ${data.casa.nome}',
            style: AppTextStyles.bodyStrong.copyWith(
              color: const Color(0xFF918D9A),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // ── Box introduttivo ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A30),
              border: Border.all(color: const Color(0xFF3A3555), width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF7B74A0),
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tieni traccia dei crediti e salda i debiti con i coinquilini in un unico click.',
                    style: TextStyle(
                      color: Color(0xFF9B94BF),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Saldi attuali ───────────────────────────────────────────────
          const _SectionTitle('SALDI ATTUALI'),
          const SizedBox(height: 12),
          _BalancesCard(rows: data.balances),
          const SizedBox(height: 28),

          // ── Trasferimenti minimi ────────────────────────────────────────
          const _SectionTitle('TRASFERIMENTI MINIMI'),
          const SizedBox(height: 12),
          _TransfersCard(
            transfers: data.transfers,
            submittingKey: submittingKey,
            onSettle: onSettleDebt,
          ),
        ],
      ),
    );
  }

  String _currentMonthYear() {
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile',
      'Maggio', 'Giugno', 'Luglio', 'Agosto',
      'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}

// ---------------------------------------------------------------------------
// Saldi card
// ---------------------------------------------------------------------------

class _BalancesCard extends StatelessWidget {
  const _BalancesCard({required this.rows});

  final List<_BalanceRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyCard(message: 'Nessun coinquilino trovato.');
    }
    return _Panel(
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _BalanceTile(row: rows[i]),
            if (i < rows.length - 1)
              const Divider(height: 1, color: Color(0xFF4A4560)),
          ],
        ],
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.row});

  final _BalanceRow row;

  @override
  Widget build(BuildContext context) {
    final Color saldoColor;
    final String saldoText;

    if (row.isCurrentUser) {
      saldoColor = const Color(0xFF918D9A);
      saldoText = '−';
    } else if (row.saldo > 0.01) {
      saldoColor = const Color(0xFF5DFF71);
      saldoText = '+€${_fmt(row.saldo)}';
    } else if (row.saldo < -0.01) {
      saldoColor = const Color(0xFFFF6767);
      saldoText = '-€${_fmt(row.saldo.abs())}';
    } else {
      saldoColor = const Color(0xFF918D9A);
      saldoText = '±€0.00';
    }

    final displayName = row.isCurrentUser ? '${row.name} (Tu)' : row.name;
    final showBreakdown =
        !row.isCurrentUser && row.credito > 0.01 && row.debito > 0.01;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(initials: row.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: const Color(0xFFDDDAE8),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                saldoText,
                style: TextStyle(
                  color: saldoColor,
                  fontSize: 19,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (showBreakdown) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 50),
              child: Row(
                children: [
                  _BreakdownChip(
                    label: 'Mi deve',
                    value: '€${_fmt(row.credito)}',
                    color: const Color(0xFF3DCC55),
                  ),
                  const SizedBox(width: 8),
                  _BreakdownChip(
                    label: 'Devo',
                    value: '€${_fmt(row.debito)}',
                    color: const Color(0xFFFF6767),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  const _BreakdownChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(color: color.withValues(alpha: 0.70)),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trasferimenti minimi card
// ---------------------------------------------------------------------------

class _TransfersCard extends StatelessWidget {
  const _TransfersCard({
    required this.transfers,
    required this.submittingKey,
    required this.onSettle,
  });

  final List<_TransferRow> transfers;
  final String? submittingKey;
  final Future<void> Function(String creditorId, String creditorName) onSettle;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const _EmptyCard(message: 'I debiti sono in pari 🎉');
    }
    return _Panel(
      child: Column(
        children: [
          for (int i = 0; i < transfers.length; i++) ...[
            _TransferTile(
              transfer: transfers[i],
              submitting: submittingKey == transfers[i].creditorId,
              disabled: submittingKey != null,
              onSettle: () =>
                  onSettle(transfers[i].creditorId, transfers[i].creditorName),
            ),
            if (i < transfers.length - 1)
              const Divider(height: 1, color: Color(0xFF4A4560)),
          ],
        ],
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.transfer,
    required this.submitting,
    required this.disabled,
    required this.onSettle,
  });

  final _TransferRow transfer;
  final bool submitting;
  final bool disabled;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _Avatar(initials: transfer.debtorInitials),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyStrong.copyWith(
                  color: const Color(0xFFDDDAE8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(text: transfer.debtorName),
                  const TextSpan(
                    text: ' paga ',
                    style: TextStyle(color: Color(0xFF918D9A)),
                  ),
                  TextSpan(text: transfer.creditorName),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '€${_fmt(transfer.amount)}',
            style: const TextStyle(
              color: AppColors.lockOrange,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          if (submitting)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.lockOrange,
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
                      Colors.white.withValues(alpha: 0.00),
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
                  onPressed: disabled ? null : onSettle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Torna in Pari',
                    style: TextStyle(
                      color: AppColors.lockOrange,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI helpers
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _avatarColor(initials),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF312B4A),
        border: Border.all(color: const Color(0xFF4A4560), width: 1.2),
        borderRadius: BorderRadius.circular(AppSizes.radius8),
      ),
      child: child,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: AppTextStyles.bodyStrong.copyWith(
            color: const Color(0xFFC1BFC8),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.screenTitleStrong.copyWith(
        color: const Color(0xFFC1BFC8),
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _PareggiaData {
  const _PareggiaData({
    required this.casa,
    required this.balances,
    required this.transfers,
  });

  final Casa casa;
  final List<_BalanceRow> balances;
  final List<_TransferRow> transfers;
}

class _BalanceRow {
  const _BalanceRow({
    required this.id,
    required this.name,
    required this.initials,
    required this.credito,
    required this.debito,
    required this.isCurrentUser,
  });

  final String id;
  final String name;
  final String initials;
  final double credito; // questa persona mi deve
  final double debito;  // devo a questa persona
  final bool isCurrentUser;

  double get saldo => credito - debito; // positivo = mi deve, negativo = devo io
}

class _TransferRow {
  const _TransferRow({
    required this.creditorId,
    required this.creditorName,
    required this.creditorInitials,
    required this.debtorName,
    required this.debtorInitials,
    required this.amount,
  });

  final String creditorId;
  final String creditorName;
  final String creditorInitials;
  final String debtorName;
  final String debtorInitials;
  final double amount;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _displayName(Inquilino inquilino) {
  final username = inquilino.username.trim();
  if (username.isNotEmpty) return username;
  return inquilino.email.trim().isEmpty ? 'Coinquilino' : inquilino.email;
}

bool _isCurrentUser(Inquilino inquilino) {
  final userId = ApiProvider.client.currentUserId?.trim();
  if (userId != null && userId.isNotEmpty) return inquilino.id == userId;
  final email = ApiProvider.client.currentUserEmail?.trim().toLowerCase();
  if (email == null || email.isEmpty) return false;
  return inquilino.email.trim().toLowerCase() == email;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _avatarColor(String initials) {
  const colors = [
    Color(0xFF315173),
    Color(0xFFEE7274),
    Color(0xFF17A832),
    Color(0xFF584036),
    Color(0xFF2D5E3F),
  ];
  return colors[initials.codeUnitAt(0) % colors.length];
}

String _fmt(double value) => value.toStringAsFixed(2);
