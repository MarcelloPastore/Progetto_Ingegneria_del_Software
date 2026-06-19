import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';

class PareggiaContiScreen extends ConsumerStatefulWidget {
  const PareggiaContiScreen({super.key});

  static const String routeName = '/spese/pareggia-conti';

  @override
  ConsumerState<PareggiaContiScreen> createState() =>
      _PareggiaContiScreenState();
}

class _PareggiaContiScreenState extends ConsumerState<PareggiaContiScreen> {
  late Future<PareggiaData?> _future;
  bool _initialized = false;
  String? _submittingKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _loadData();
  }

  Future<PareggiaData?> _loadData() {
    final casaId = ActiveCasaScope.read(context).selectedCasaId;
    return ref.read(pareggiaDataProvider(casaId).future);
  }

  Future<void> _settleDebt(String creditorId, String creditorName) async {
    if (_submittingKey != null) return;
    setState(() => _submittingKey = creditorId);
    try {
      final data = await _future;
      if (data == null) return;
      await ref
          .read(speseViewModelProvider(data.casa.id).notifier)
          .pareggiaConti([creditorId]);
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
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<PareggiaData?>(
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
                        style: TextStyle(color: AppColors.textOnDark),
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
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p8,
                AppSizes.p16,
                AppSizes.p14,
              ),
              child: MainCtaButton(
                label: 'Torna alle spese',
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(ListaSpeseAdminScreen.routeName),
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

  final PareggiaData data;
  final String? submittingKey;
  final Future<void> Function(String creditorId, String creditorName)
  onSettleDebt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p24,
        AppSizes.p16,
        AppSizes.p16,
      ),
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
                'Spese',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.brandAccent,
                  fontSize: AppSizes.p23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Pareggia i conti',
            style: AppTextStyles.screenTitleStrong.copyWith(
              fontSize: AppSizes.p22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            '${_currentMonthYear()} · ${data.casa.nome}',
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textDim,
              fontSize: AppSizes.p16,
            ),
          ),
          const SizedBox(height: AppSizes.p16),

          // ── Box introduttivo ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p14,
              vertical: AppSizes.p12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkCard,
              border: Border.all(
                color: AppColors.dividerDark,
                width: AppSizes.p1,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radius10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textMutedDark,
                  size: AppSizes.p18,
                ),
                const SizedBox(width: AppSizes.p10),
                const Expanded(
                  child: Text(
                    'Tieni traccia dei crediti e salda i debiti con i coinquilini in un unico click.',
                    style: TextStyle(
                      color: AppColors.textMutedSoft,
                      fontSize: AppSizes.p13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p24),

          // ── Saldi attuali ───────────────────────────────────────────────
          const _SectionTitle('SALDI ATTUALI'),
          const SizedBox(height: AppSizes.p12),
          _BalancesCard(rows: data.balances),
          const SizedBox(height: AppSizes.p28),

          // ── Trasferimenti minimi ────────────────────────────────────────
          const _SectionTitle('TRASFERIMENTI MINIMI'),
          const SizedBox(height: AppSizes.p12),
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
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}

// ---------------------------------------------------------------------------
// Saldi card
// ---------------------------------------------------------------------------

class _BalancesCard extends StatelessWidget {
  const _BalancesCard({required this.rows});

  final List<BalanceRow> rows;

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
              const Divider(
                height: AppSizes.p1,
                color: AppColors.dividerOnDark,
              ),
          ],
        ],
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.row});

  final BalanceRow row;

  @override
  Widget build(BuildContext context) {
    final Color saldoColor;
    final String saldoText;

    if (row.isCurrentUser) {
      saldoColor = AppColors.textDim;
      saldoText = '−';
    } else if (row.saldo > 0.01) {
      saldoColor = AppColors.statusPositive;
      saldoText = '+€${_fmt(row.saldo)}';
    } else if (row.saldo < -0.01) {
      saldoColor = AppColors.statusNegative;
      saldoText = '-€${_fmt(row.saldo.abs())}';
    } else {
      saldoColor = AppColors.textDim;
      saldoText = '±€0.00';
    }

    final displayName = row.isCurrentUser ? '${row.name} (Tu)' : row.name;
    final showBreakdown =
        !row.isCurrentUser && row.credito > 0.01 && row.debito > 0.01;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p14,
        vertical: AppSizes.p10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(userId: row.id, username: row.name, radius: 19),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  displayName,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textMutedLight,
                    fontSize: AppSizes.p17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                saldoText,
                style: TextStyle(
                  color: saldoColor,
                  fontSize: AppSizes.p19,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (showBreakdown) ...[
            const SizedBox(height: AppSizes.p6),
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.p50),
              child: Row(
                children: [
                  _BreakdownChip(
                    label: 'Mi deve',
                    value: '€${_fmt(row.credito)}',
                    color: AppColors.statusSuccess,
                  ),
                  const SizedBox(width: AppSizes.p8),
                  _BreakdownChip(
                    label: 'Devo',
                    value: '€${_fmt(row.debito)}',
                    color: AppColors.statusNegative,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSizes.radius6),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
          width: AppSizes.p1,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: AppSizes.p12,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(color: color.withValues(alpha: 0.70)),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
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

  final List<TransferRow> transfers;
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
              const Divider(
                height: AppSizes.p1,
                color: AppColors.dividerOnDark,
              ),
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

  final TransferRow transfer;
  final bool submitting;
  final bool disabled;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p14,
        vertical: AppSizes.p10,
      ),
      child: Row(
        children: [
          UserAvatar(
            userId: transfer.creditorId,
            username: transfer.creditorName,
            radius: 19,
          ),
          const SizedBox(width: AppSizes.p10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: AppSizes.p16,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(text: transfer.debtorName),
                  const TextSpan(
                    text: ' paga ',
                    style: TextStyle(color: AppColors.textDim),
                  ),
                  TextSpan(text: transfer.creditorName),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          Text(
            '€${_fmt(transfer.amount)}',
            style: const TextStyle(
              color: AppColors.lockOrange,
              fontSize: AppSizes.p16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSizes.p10),
          if (submitting)
            const SizedBox(
              width: AppSizes.p28,
              height: AppSizes.p28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.lockOrange,
              ),
            )
          else
            SizedBox(
              height: AppSizes.p34,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(0.50, 0.00),
                    end: const Alignment(0.50, 1.00),
                    colors: [
                      AppColors.textOnDark.withValues(alpha: 0.20),
                      AppColors.textOnDark.withValues(alpha: 0.00),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: AppSizes.p2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: AppColors.lockOrange,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: AppColors.shadowOverlay,
                      blurRadius: AppSizes.p4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: disabled ? null : onSettle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.transparent,
                    disabledBackgroundColor: AppColors.transparent,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                    ),
                  ),
                  child: const Text(
                    'Torna in Pari',
                    style: TextStyle(
                      color: AppColors.lockOrange,
                      fontSize: AppSizes.p13,
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkMuted,
        border: Border.all(
          color: AppColors.dividerOnDark,
          width: AppSizes.p1_2,
        ),
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
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Text(
          message,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textDisabled,
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
        color: AppColors.textDisabled,
        fontSize: AppSizes.p14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

String _fmt(double value) => value.toStringAsFixed(2);
