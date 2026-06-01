import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/icone_fab.dart';
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
  bool _fabActionsVisible = false;
  String? _submittingKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _future = _loadData();
  }

  Future<_PareggiaData?> _loadData() async {
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }

    final casa = activeCasaController.resolveCasa(caseUtente);
    final inquilini = await ApiProvider.casa.listInquilini(casa.id);
    final balances = <_BalanceRow>[];

    for (final inquilino in inquilini) {
      final results = await Future.wait<double>([
        ApiProvider.spese
            .getCreditoVerso(casa.id, inquilino.id)
            .catchError((_) => 0.0),
        ApiProvider.spese
            .getDebitoVerso(casa.id, inquilino.id)
            .catchError((_) => 0.0),
      ]);
      balances.add(
        _BalanceRow(
          id: inquilino.id,
          name: _displayName(inquilino),
          initials: _initials(_displayName(inquilino)),
          amount: results[0] - results[1],
          isCurrentUser: _isCurrentUser(inquilino),
        ),
      );
    }

    balances.sort((a, b) => a.name.compareTo(b.name));
    return _PareggiaData(
      casa: casa,
      balances: balances,
      transfers: _minimalTransfers(balances),
    );
  }

  Future<void> _markTransfer(_TransferRow transfer) async {
    setState(() => _submittingKey = transfer.key);
    try {
      final data = await _future;
      if (data == null) {
        return;
      }
      await ApiProvider.spese.pareggia(data.casa.id, {
        'daInquilinoId': transfer.fromId,
        'aInquilinoId': transfer.toId,
        'importo': transfer.amount,
      });
      if (!mounted) {
        return;
      }
      setState(() {
        _future = _loadData();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trasferimento segnato.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile segnare il trasferimento.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingKey = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151127),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _fabActionsVisible = !_fabActionsVisible;
          });
        },
        backgroundColor: AppColors.brandAccent,
        elevation: AppSizes.p6,
        child: const Icon(
          Icons.add,
          size: AppSizes.p38,
          color: AppColors.textOnDark,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<_PareggiaData?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data;
                if (data == null) {
                  return const _PareggiaState(message: 'Dati non disponibili.');
                }
                return _PareggiaContent(
                  data: data,
                  submittingKey: _submittingKey,
                  onMarkTransfer: _markTransfer,
                );
              },
            ),
            if (_fabActionsVisible)
              Positioned(
                left: AppSizes.p10,
                right: AppSizes.p10,
                bottom: AppSizes.p90,
                child: DashboardFabActionsPanel(
                  onActionSelected: (routeName) {
                    setState(() {
                      _fabActionsVisible = false;
                    });
                    Navigator.of(context).pushNamed(routeName);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PareggiaContent extends StatelessWidget {
  const _PareggiaContent({
    required this.data,
    required this.submittingKey,
    required this.onMarkTransfer,
  });

  final _PareggiaData data;
  final String? submittingKey;
  final ValueChanged<_TransferRow> onMarkTransfer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p24,
        AppSizes.p16,
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
                'Spese',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.brandAccent,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Pareggia i conti',
            style: AppTextStyles.screenTitleStrong.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            'Giugno 2026 - ${data.casa.nome}',
            style: AppTextStyles.bodyStrong.copyWith(
              color: const Color(0xFF918D9A),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.p30),
          const _SectionTitle('SALDI ATTUALI'),
          const SizedBox(height: AppSizes.p12),
          _BalancesCard(rows: data.balances),
          const SizedBox(height: AppSizes.p28),
          const _SectionTitle('TRASFERIMENTI MINIMI'),
          const SizedBox(height: AppSizes.p12),
          _TransfersCard(
            rows: data.transfers,
            submittingKey: submittingKey,
            onMarkTransfer: onMarkTransfer,
          ),
          const SizedBox(height: AppSizes.p18),
          OutlinedButton(
            onPressed: () => Navigator.of(
              context,
            ).pushReplacementNamed(ListaSpeseAdminScreen.routeName),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4695EA), width: 2),
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius15),
              ),
            ),
            child: const Text(
              'Torna alle spese',
              style: TextStyle(
                color: Color(0xFF4695EA),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancesCard extends StatelessWidget {
  const _BalancesCard({required this.rows});

  final List<_BalanceRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyCard(message: 'Nessun saldo disponibile.');
    }

    return _Panel(
      child: Column(
        children: [
          for (int index = 0; index < rows.length; index++) ...[
            _BalanceTile(row: rows[index]),
            if (index < rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _TransfersCard extends StatelessWidget {
  const _TransfersCard({
    required this.rows,
    required this.submittingKey,
    required this.onMarkTransfer,
  });

  final List<_TransferRow> rows;
  final String? submittingKey;
  final ValueChanged<_TransferRow> onMarkTransfer;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyCard(message: 'I conti sono gia pareggiati.');
    }

    return _Panel(
      child: Column(
        children: [
          for (int index = 0; index < rows.length; index++) ...[
            _TransferTile(
              row: rows[index],
              submitting: submittingKey == rows[index].key,
              onPressed: () => onMarkTransfer(rows[index]),
            ),
            if (index < rows.length - 1) const Divider(height: 1),
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
    final isPositive = row.amount >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p8,
      ),
      child: Row(
        children: [
          _Avatar(initials: row.initials),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              row.isCurrentUser ? '${row.name} (Tu)' : row.name,
              style: AppTextStyles.bodyStrong.copyWith(
                color: const Color(0xFFC1BFC8),
                fontSize: 18,
              ),
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}${_formatCurrency(row.amount.abs())}',
            style: TextStyle(
              color: isPositive
                  ? const Color(0xFF5DFF71)
                  : const Color(0xFFFF6767),
              fontSize: 19,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.row,
    required this.submitting,
    required this.onPressed,
  });

  final _TransferRow row;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p8,
      ),
      child: Row(
        children: [
          _Avatar(initials: row.fromInitials),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              '${row.fromName} paga ${row.toName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong.copyWith(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ),
          Text(
            _formatCurrency(row.amount),
            style: const TextStyle(
              color: Color(0xFFFFDF24),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          ElevatedButton(
            onPressed: submitting ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p8,
              ),
              minimumSize: const Size(64, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius16),
                side: const BorderSide(color: AppColors.primaryBorder),
              ),
            ),
            child: Text(
              submitting ? '...' : 'Segna',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
      width: 34,
      height: 34,
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
        border: Border.all(color: const Color(0xFF77727F), width: 1.2),
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
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PareggiaState extends StatelessWidget {
  const _PareggiaState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
      ),
    );
  }
}

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
    required this.amount,
    required this.isCurrentUser,
  });

  final String id;
  final String name;
  final String initials;
  final double amount;
  final bool isCurrentUser;
}

class _TransferRow {
  const _TransferRow({
    required this.fromId,
    required this.toId,
    required this.fromName,
    required this.toName,
    required this.fromInitials,
    required this.amount,
  });

  final String fromId;
  final String toId;
  final String fromName;
  final String toName;
  final String fromInitials;
  final double amount;

  String get key => '$fromId-$toId-${amount.toStringAsFixed(2)}';
}

List<_TransferRow> _minimalTransfers(List<_BalanceRow> balances) {
  final debtors = balances
      .where((row) => row.amount < -0.01)
      .map((row) => _WorkingBalance(row: row, amount: row.amount.abs()))
      .toList();
  final creditors = balances
      .where((row) => row.amount > 0.01)
      .map((row) => _WorkingBalance(row: row, amount: row.amount))
      .toList();
  final transfers = <_TransferRow>[];
  var debtorIndex = 0;
  var creditorIndex = 0;

  while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
    final debtor = debtors[debtorIndex];
    final creditor = creditors[creditorIndex];
    final amount = debtor.amount < creditor.amount
        ? debtor.amount
        : creditor.amount;
    transfers.add(
      _TransferRow(
        fromId: debtor.row.id,
        toId: creditor.row.id,
        fromName: debtor.row.name,
        toName: creditor.row.name,
        fromInitials: debtor.row.initials,
        amount: amount,
      ),
    );
    debtor.amount -= amount;
    creditor.amount -= amount;
    if (debtor.amount <= 0.01) {
      debtorIndex++;
    }
    if (creditor.amount <= 0.01) {
      creditorIndex++;
    }
  }

  return transfers;
}

class _WorkingBalance {
  _WorkingBalance({required this.row, required this.amount});

  final _BalanceRow row;
  double amount;
}

String _displayName(Inquilino inquilino) {
  final name = inquilino.nomeCompleto.trim();
  if (name.isNotEmpty) {
    return name;
  }
  if (inquilino.username.trim().isNotEmpty) {
    return inquilino.username.trim();
  }
  return inquilino.email.trim().isEmpty ? 'Coinquilino' : inquilino.email;
}

bool _isCurrentUser(Inquilino inquilino) {
  final email = ApiProvider.client.currentUserEmail?.trim().toLowerCase();
  if (email == null || email.isEmpty) {
    return false;
  }
  return inquilino.email.trim().toLowerCase() == email;
}

String _initials(String name) {
  final parts = name
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
    Color(0xFF315173),
    Color(0xFFEE7274),
    Color(0xFF17A832),
    Color(0xFF584036),
    Color(0xFF2D5E3F),
  ];
  return colors[initials.codeUnitAt(0) % colors.length];
}

String _formatCurrency(double value) {
  return '€${value.toStringAsFixed(0)}';
}
