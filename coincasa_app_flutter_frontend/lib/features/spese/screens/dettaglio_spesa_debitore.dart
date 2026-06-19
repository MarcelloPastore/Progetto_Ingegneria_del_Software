import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/formatters.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/spese/screens/elimina_spesa.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_membro.dart';
import 'package:coincasa_app/features/spese/screens/modifiche_spese_negata.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';

class DettaglioSpesaDebitoreScreen extends ConsumerStatefulWidget {
  const DettaglioSpesaDebitoreScreen({super.key});

  static const String routeName = '/spese/dettaglio-debitore';

  @override
  ConsumerState<DettaglioSpesaDebitoreScreen> createState() =>
      _DettaglioSpesaDebitoreScreenState();
}

class _DettaglioSpesaDebitoreScreenState
    extends ConsumerState<DettaglioSpesaDebitoreScreen> {
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
    final caseUtente = await ref.read(listaCaseViewModelProvider.future);
    if (caseUtente.isEmpty) {
      return null;
    }
    final casa = activeCasaController.resolveCasa(caseUtente);
    final speseState = await ref.read(speseViewModelProvider(casa.id).future);
    final notifier = ref.read(speseViewModelProvider(casa.id).notifier);
    final spesa = await notifier.getSpesaById(spesaId);
    final quote = await notifier
        .getQuoteSpesa(spesa.id)
        .catchError((_) => <Quota>[]);
    final inquilini = speseState.inquilini;
    final authUser = await ref.read(authViewModelProvider.future);
    final currentUser = currentSpeseInquilino(inquilini, authUser);
    return _DebtorDetailData(
      casa: casa,
      spesa: spesa,
      quote: quote,
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
      await ref
          .read(speseViewModelProvider(casaId).notifier)
          .pagaQuota(spesaId, quotaId);
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
      backgroundColor: AppColors.darkBackground,
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
                  style: TextStyle(color: AppColors.textOnDark),
                ),
              );
            }
            return _DebtorDetailContent(
              data: data,
              isPaying: _isPaying,
              onPayQuota: (quotaId) =>
                  _payQuota(data.casa.id, data.spesa.id, quotaId),
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
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p21,
        AppSizes.p14,
        AppSizes.p21,
        AppSizes.p34,
      ),
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
                    color: AppColors.featureAccent,
                    size: AppSizes.p24,
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                const Text(
                  'Dettaglio spesa',
                  style: TextStyle(
                    color: AppColors.featureAccent,
                    fontSize: AppSizes.p19,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p34),
            Text(
              formatCurrency(data.spesa.importo),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p32,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.p4),
            Text(
              '${data.spesa.descrizione} - ${formatFullDate(data.spesa.data)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: AppSizes.p14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            _InfoBox(payingNames: payingNames, quota: quota),
            const SizedBox(height: AppSizes.p26),
            const Text(
              'STATO QUOTE',
              style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: AppSizes.p17,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            _QuotesBox(data: data, isPaying: isPaying, onPayQuota: onPayQuota),
            if (canManage) ...[
              const SizedBox(height: AppSizes.p18),
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
                  const SizedBox(width: AppSizes.p12),
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
            const SizedBox(height: AppSizes.p70),
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
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p13,
        AppSizes.p16,
        AppSizes.p13,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkCardAlt,
        border: Border.all(color: AppColors.borderSubtle, width: AppSizes.p1_2),
        borderRadius: BorderRadius.circular(AppSizes.radius10),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Chi deve pagare', value: payingNames),
          const Divider(height: AppSizes.p12, color: AppColors.borderSubtle),
          _InfoRow(label: 'Quota per persone', value: formatCurrency(quota)),
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
              color: AppColors.textDim,
              fontSize: AppSizes.p15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: AppSizes.p15,
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
        color: AppColors.surfaceDarkCardAlt,
        border: Border.all(color: AppColors.borderSubtle, width: AppSizes.p1_2),
        borderRadius: BorderRadius.circular(AppSizes.radius10),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p12,
        AppSizes.p8,
        AppSizes.p12,
        AppSizes.p8,
      ),
      child: Column(
        children: [
          for (int index = 0; index < rows.length; index++) ...[
            _QuoteTile(
              row: rows[index],
              isPaying: isPaying,
              onPayQuota: onPayQuota,
            ),
            if (index < rows.length - 1)
              const Divider(height: AppSizes.p1, color: AppColors.borderSubtle),
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
    final showPayButton =
        row.isCurrentUser &&
        !row.excluded &&
        row.quotaId != null &&
        row.status == 'Da pagare';

    return Container(
      height: AppSizes.p47,
      color: row.isCurrentUser
          ? AppColors.textMutedDark
          : AppColors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p2),
      child: Row(
        children: [
          Opacity(
            opacity: row.excluded ? 0.35 : 1.0,
            child: UserAvatar(
              userId: row.userId,
              username: row.initials,
              radius: 17.5,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              row.name,
              style: TextStyle(
                color: row.excluded
                    ? AppColors.textMutedDark
                    : AppColors.textOnDark,
                fontSize: AppSizes.p16,
                fontFamily: 'Inter',
                fontStyle: row.excluded ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showPayButton)
            if (isPaying)
              const SizedBox(
                width: AppSizes.p24,
                height: AppSizes.p24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.lockOrange,
                  ),
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
                        AppColors.textOnDark.withValues(alpha: 0),
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
                    onPressed: () => onPayQuota(row.quotaId!),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.transparent,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radius12),
                      ),
                    ),
                    child: const Text(
                      'Paga',
                      style: TextStyle(
                        color: AppColors.lockOrange,
                        fontSize: AppSizes.p14,
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
                fontSize: AppSizes.p15,
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

class _SmallManageButton extends StatelessWidget {
  const _SmallManageButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.featureAccent),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.featureAccent),
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
      height: AppSizes.p49,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            side: const BorderSide(
              color: AppColors.textMutedDark,
              width: AppSizes.p1_3,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: AppSizes.p18,
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
    this.userId = '',
  });

  final String name;
  final String initials;
  final String status;
  final Color statusColor;
  final bool isCurrentUser;
  final bool excluded;
  final String? quotaId;
  final String userId;
}

List<_QuoteRow> _quoteRows(_DebtorDetailData data) {
  final projection = SpesaDetailProjection.from(
    spesa: data.spesa,
    quote: data.quote,
    inquilini: data.inquilini,
    currentUserId: data.currentUserId,
  );
  return projection.rowsIncludingExcluded
      .map(
        (row) => _QuoteRow(
          name: row.name,
          initials: row.initials,
          status: row.isExcluded
              ? 'escluso/a'
              : row.isPaid
              ? 'Pagato'
              : 'Da pagare',
          statusColor: row.isExcluded
              ? AppColors.textMutedDark
              : row.isPaid
              ? AppColors.statusPositive
              : AppColors.statusNegative,
          isCurrentUser: row.isCurrentUser,
          excluded: row.isExcluded,
          quotaId: row.quotaId,
          userId: row.userId,
        ),
      )
      .toList(growable: false);
}

String _payingNames(_DebtorDetailData data) {
  return SpesaDetailProjection.from(
    spesa: data.spesa,
    quote: data.quote,
    inquilini: data.inquilini,
    currentUserId: data.currentUserId,
  ).payingNames;
}
