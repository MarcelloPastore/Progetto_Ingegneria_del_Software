import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/data/models/quota.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/formatters.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/delete_confirm_dialog.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/ui/spese/screens/lista_spese.dart';
import 'package:coincasa_app/ui/spese/screens/form_modifica_spesa.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';

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
    final caseUtente = await ref.read(listaCaseViewModelProvider.future);
    if (caseUtente.isEmpty) {
      return null;
    }

    final casa = activeCasaController.resolveCasa(caseUtente);
    final argSpesa = args is Spesa ? args : null;
    final spesaId = argSpesa?.id ?? (args is String ? args : null);
    if (spesaId == null || spesaId.isEmpty) {
      return null;
    }

    final speseState = await ref.read(speseViewModelProvider(casa.id).future);
    final notifier = ref.read(speseViewModelProvider(casa.id).notifier);
    final results = await Future.wait<dynamic>([
      argSpesa == null
          ? notifier.getSpesaById(spesaId)
          : Future<Spesa>.value(argSpesa),
      notifier.getQuoteSpesa(spesaId).catchError((_) => const <Quota>[]),
    ]);

    final inquilini = speseState.inquilini;
    final authUser = await ref.read(authViewModelProvider.future);
    final currentUser = currentSpeseInquilino(inquilini, authUser);

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
      await ref
          .read(speseViewModelProvider(casaId).notifier)
          .pagaQuota(spesaId, quotaId);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
              onPayQuota: (quotaId) =>
                  _payQuota(data.casa.id, data.spesa.id, quotaId),
              onDelete: () => ref
                  .read(speseViewModelProvider(data.casa.id).notifier)
                  .deleteSpesa(data.spesa.id),
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
    required this.onDelete,
  });

  final _SpesaDetailData data;
  final bool isPaying;
  final ValueChanged<String> onPayQuota;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final projection = SpesaDetailProjection.from(
      spesa: data.spesa,
      quote: data.quote,
      inquilini: data.inquilini,
      currentUserId: data.currentUserId,
    );
    final rows = projection.rows;

    final isHomeAdmin = ActiveCasaScope.of(context).isHomeAdmin;
    final isCreator = data.spesa.isCreatedBy(data.currentUserId);
    final hasAnyPaidQuota = projection.hasAnyPaidQuota;
    final hasAnticipatore = spesaHasAnticipatore(data.spesa);
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
                        fontSize: AppSizes.p23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p48),
                Text(
                  formatCurrency(data.spesa.importo),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    fontSize: AppSizes.p38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSizes.p6),
                Text(
                  '${data.spesa.descrizione} - ${formatLongDate(data.spesa.data)}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textSubtle,
                    fontSize: AppSizes.p18,
                  ),
                ),
                if (hasAnyPaidQuota) ...[
                  const SizedBox(height: AppSizes.p16),
                  const _LockedBanner(),
                ],
                const SizedBox(height: AppSizes.p24),
                _CreatorAvatarRow(
                  creatoreNome: data.spesa.creatoreNome,
                  creatoreId: data.spesa.creatoreId,
                ),
                const SizedBox(height: AppSizes.p24),
                _SummaryCard(
                  payerNames: projection.payerNames.isEmpty
                      ? const ['Nessuno']
                      : projection.payerNames,
                  quotaPerPersona: projection.quotaPerPersona,
                  anticipatoreNome: anticipatoreNome,
                  dataScadenza: data.spesa.dataScadenza,
                  isRicorrente: data.spesa.isRicorrente,
                  cadenzaMesi: data.spesa.raw['cadenzaMesi'] as int?,
                  cadenzaGiorni: data.spesa.raw['cadenzaGiorni'] as int?,
                ),
                const SizedBox(height: AppSizes.p32),
                Text(
                  'STATO QUOTE',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: AppSizes.p21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSizes.p10),
                _QuoteStatusCard(
                  rows: rows,
                  isPaying: isPaying,
                  onPayQuota: onPayQuota,
                ),
                const SizedBox(height: AppSizes.p32),
                const _ScontrinoAllegatoMock(),
              ],
            ),
          ),
        ),
        DetailActionsBar(
          modifyLabel: 'Modifica spesa',
          deleteLabel: 'Elimina spesa',
          backLabel: 'Torna alle spese',
          isCreator: isCreator,
          canDelete: isCreator || isHomeAdmin,
          onModify: hasAnyPaidQuota
              ? null
              : () => Navigator.of(context).pushNamed(
                  ModificaSpesaAdminScreen.routeName,
                  arguments: data.spesa,
                ),
          onDelete: (hasAnyPaidQuota && !isHomeAdmin)
              ? null
              : () => showDeleteConfirmDialog(
                  context: context,
                  title: 'Eliminare la spesa?',
                  description:
                      '${data.spesa.descrizione} — '
                      '€${data.spesa.importo.toStringAsFixed(2)} '
                      'verrà rimossa definitivamente dalla lista.',
                  onConfirm: onDelete,
                  onSuccess: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(ListaSpeseAdminScreen.routeName),
                ),
          onBack: () => Navigator.of(
            context,
          ).pushReplacementNamed(ListaSpeseAdminScreen.routeName),
        ),
      ],
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p14,
        vertical: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: AppColors.turniAssigneeMenuSurface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        border: Border.all(
          color: AppColors.statusWarning,
          width: AppSizes.p1_5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSizes.p1),
            child: Icon(
              Icons.lock_rounded,
              color: AppColors.statusWarning,
              size: AppSizes.p20,
            ),
          ),
          const SizedBox(width: AppSizes.p10),
          const Expanded(
            child: Text(
              'Questa spesa ha quote già pagate: modifica ed eliminazione bloccate.',
              style: TextStyle(
                color: AppColors.statusWarning,
                fontSize: AppSizes.p13,
                fontWeight: FontWeight.w600,
                height: AppSizes.p1_4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorAvatarRow extends StatelessWidget {
  const _CreatorAvatarRow({required this.creatoreNome, this.creatoreId = ''});

  final String creatoreNome;
  final String creatoreId;

  @override
  Widget build(BuildContext context) {
    final nome = creatoreNome.trim();
    final initials = nome.isNotEmpty ? _initials(nome) : 'C';
    final seed = creatoreId.isNotEmpty ? creatoreId : initials;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: AppSizes.p46,
          height: AppSizes.p46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: userAvatarColorsForSeed(seed).background,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Text(
          '${nome.isNotEmpty ? nome : 'Coinquilino'} ha creato questa spesa',
          style: const TextStyle(
            color: AppColors.textSubtle,
            fontSize: AppSizes.p15,
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
    this.dataScadenza,
    this.isRicorrente = false,
    this.cadenzaMesi,
    this.cadenzaGiorni,
  });

  final List<String> payerNames;
  final double quotaPerPersona;
  final String? anticipatoreNome;
  final DateTime? dataScadenza;
  final bool isRicorrente;
  final int? cadenzaMesi;
  final int? cadenzaGiorni;

  String get _frequenzaLabel {
    if (cadenzaMesi != null) {
      return switch (cadenzaMesi) {
        1 => 'Mensile',
        2 => 'Bimestrale',
        3 => 'Trimestrale',
        12 => 'Annuale',
        _ => 'Ogni $cadenzaMesi mesi',
      };
    }
    if (cadenzaGiorni != null) {
      return switch (cadenzaGiorni) {
        30 => 'Mensile',
        60 => 'Bimestrale',
        90 => 'Trimestrale',
        365 => 'Annuale',
        _ => 'Ogni $cadenzaGiorni giorni',
      };
    }
    return 'Ricorrente';
  }

  @override
  Widget build(BuildContext context) {
    final hasAnticipatore =
        anticipatoreNome != null && anticipatoreNome!.trim().isNotEmpty;
    final hasScadenza = dataScadenza != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkCard,
        border: Border.all(color: AppColors.borderMuted, width: AppSizes.p1_2),
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
          const Divider(color: AppColors.dividerDark, height: AppSizes.p18),
          _SummaryRow(
            label: 'Quota per persone',
            value: formatCurrency(quotaPerPersona),
          ),
          if (hasScadenza) ...[
            const Divider(color: AppColors.dividerDark, height: AppSizes.p18),
            _SummaryRow(
              label: 'Scadenza',
              value: formatLongDate(dataScadenza!),
              valueColor: AppColors.keyYellow,
            ),
          ],
          if (isRicorrente) ...[
            const Divider(color: AppColors.dividerDark, height: AppSizes.p18),
            _SummaryRow(
              label: 'Frequenza',
              value: _frequenzaLabel,
              valueColor: AppColors.brandAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textSubtle,
              fontSize: AppSizes.p18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyStrong.copyWith(
              color: valueColor ?? AppColors.textOnDark,
              fontSize: AppSizes.p18,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mock receipt section
// ---------------------------------------------------------------------------

class _ScontrinoAllegatoMock extends StatelessWidget {
  const _ScontrinoAllegatoMock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCONTRINO ALLEGATO',
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.textDisabled,
            fontSize: AppSizes.p21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSizes.p10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSizes.p14),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ESSELUNGA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E1B2E),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(height: AppSizes.p2),
              Text(
                'Via Roma, 15 – Milano',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8D889C), fontSize: 9),
              ),
              Divider(height: 16, color: Color(0xFFD6D2E6)),
              _ReceiptRow(label: 'Pasta 500g', value: '€ 1,59'),
              _ReceiptRow(label: 'Latte intero', value: '€ 2,10'),
              _ReceiptRow(label: 'Pane casereccio', value: '€ 2,80'),
              _ReceiptRow(label: 'Verdura mista', value: '€ 5,30'),
              _ReceiptRow(label: 'Succo di frutta', value: '€ 4,20'),
              _ReceiptRow(label: 'Biscotti assortiti', value: '€ 2,41'),
              Divider(height: 14, color: Color(0xFFD6D2E6)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTALE',
                    style: TextStyle(
                      color: Color(0xFF1E1B2E),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '€ 18,40',
                    style: TextStyle(
                      color: Color(0xFF1E1B2E),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF5B5668), fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF5B5668), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _QuoteStatusCard extends StatelessWidget {
  const _QuoteStatusCard({
    required this.rows,
    required this.isPaying,
    required this.onPayQuota,
  });

  final List<SpesaQuotaRow> rows;
  final bool isPaying;
  final ValueChanged<String> onPayQuota;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkCard,
        border: Border.all(color: AppColors.borderMuted, width: AppSizes.p1_4),
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
                color: AppColors.textMutedDark,
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

  final SpesaQuotaRow row;
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
        ? AppColors.textSubtle
        : row.isPaid
        ? AppColors.statusPositive
        : AppColors.statusNegative;

    final showPayButton =
        row.isCurrentUser &&
        !row.isPaid &&
        !row.isExcluded &&
        row.quotaId != null;

    return Row(
      children: [
        Container(
          width: AppSizes.p45,
          height: AppSizes.p45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: userAvatarColorsForSeed(
              row.userId.isNotEmpty ? row.userId : row.initials,
            ).background.withValues(alpha: muted ? 0.38 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            row.initials,
            style: TextStyle(
              color: muted ? AppColors.statusWarning : AppColors.textOnDark,
              fontSize: AppSizes.p17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p16),
        Expanded(
          child: Text(
            row.name,
            style: TextStyle(
              color: muted ? AppColors.textSubtle : AppColors.textOnDark,
              fontSize: AppSizes.p19,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.lockOrange),
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
              fontSize: AppSizes.p18,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
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
          style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textOnDark),
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
