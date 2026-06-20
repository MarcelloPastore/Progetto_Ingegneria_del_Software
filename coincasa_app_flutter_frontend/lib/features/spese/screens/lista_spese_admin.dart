import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/models/auth_user.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_admin.dart';
import 'package:coincasa_app/features/spese/screens/inserisci_spesa_admin.dart';
import 'package:coincasa_app/features/spese/screens/pareggia_conti.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';

class ListaSpeseAdminScreen extends ConsumerStatefulWidget {
  const ListaSpeseAdminScreen({super.key});

  static const String routeName = '/spese/lista';

  @override
  ConsumerState<ListaSpeseAdminScreen> createState() =>
      _ListaSpeseAdminScreenState();
}

class _ListaSpeseAdminScreenState extends ConsumerState<ListaSpeseAdminScreen>
    with RouteAware {
  /// Cache statica: sopravvive a pushReplacementNamed e autoDispose dei provider.
  static List<Spesa>? _cachedSpese;
  static Map<String, double>? _cachedSaldi;

  SpesaStatus? _activeFilter;
  @override
  void initState() {
    super.initState();
    // Invalida i provider ad ogni apertura della schermata (anche via pushReplacementNamed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final casaId = ActiveCasaScope.read(context).selectedCasaId;
      if (casaId != null) {
        ref.invalidate(speseViewModelProvider(casaId));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Chiamato quando si torna a questa schermata dopo un pop da una route superiore.
  @override
  void didPopNext() {
    super.didPopNext();
    final selectedCasaId = ActiveCasaScope.read(context).selectedCasaId;
    if (selectedCasaId != null) {
      ref.invalidate(speseViewModelProvider(selectedCasaId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCasaController = ActiveCasaScope.read(context);
    final selectedCasaId = activeCasaController.selectedCasaId;
    final currentUser = ref.watch(authViewModelProvider).valueOrNull;

    if (selectedCasaId == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    final speseAsync = ref.watch(speseViewModelProvider(selectedCasaId));

    // Aggiorna le cache ad ogni arrivo di dati freschi.
    speseAsync.whenData((state) {
      _cachedSpese = state.spese;
      _cachedSaldi = {
        'saldo': state.saldo,
        'credito': state.creditoTotale,
        'debito': state.debitoTotale,
      };
    });

    // Usa la cache come fallback durante il caricamento.
    final effectiveSpese =
        speseAsync.maybeWhen(
          data: (state) => state.spese,
          orElse: () => null,
        ) ??
        _cachedSpese;
    final effectiveSaldi =
        speseAsync.maybeWhen(
          data: (state) => {
            'saldo': state.saldo,
            'credito': state.creditoTotale,
            'debito': state.debitoTotale,
          },
          orElse: () => null,
        ) ??
        _cachedSaldi;
    final isLoading = speseAsync.isLoading && effectiveSpese == null;
    final hasSpese = (effectiveSpese?.isNotEmpty) ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (speseAsync.hasError && effectiveSpese == null)
                      Center(child: Text('Errore: ${speseAsync.error}'))
                    else
                      _buildContent(
                        context,
                        effectiveSpese ?? const [],
                        effectiveSaldi,
                        currentUser,
                      ),
                    // Indicatore sottile di refresh in background
                    if (speseAsync.isLoading && effectiveSpese != null)
                      const Positioned(
                        top: AppSizes.p0,
                        left: AppSizes.p0,
                        right: AppSizes.p0,
                        child: LinearProgressIndicator(
                          minHeight: AppSizes.p2,
                          backgroundColor: AppColors.transparent,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasSpese) _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Spesa> spese,
    Map<String, double>? saldi,
    AuthUser? currentUser,
  ) {
    if (spese.isEmpty) {
      return const _EmptyExpensesContent();
    }

    final projection = SpeseListProjection.from(
      spese,
      filter: _activeFilter,
      currentUser: currentUser,
    );
    final filtered = projection.filtered;
    final speseGroupedByMonth = projection.groupedByMonth;
    final sortedMonths = projection.sortedMonths;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.p12),
            child: Center(
              child: Column(
                children: [
                  Text(
                    ActiveCasaScope.read(context).selectedCasa?.nome ?? '',
                    style: const TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: AppSizes.p20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p4),
                  Text(
                    'Spese',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.brandAccent,
                      fontSize: AppSizes.p40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p24),

          // Monthly balance card
          if (saldi != null)
            _buildBalanceCard(saldi)
          else
            const SizedBox.shrink(),
          const SizedBox(height: AppSizes.p20),

          // Filter bar
          _buildFilterBar(),
          const SizedBox(height: AppSizes.p20),

          // Spese list or empty-filter message
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p22,
                vertical: AppSizes.p32,
              ),
              child: Center(
                child: Text(
                  'Nessuna spesa ${_filterLabel(_activeFilter!).toLowerCase()}.',
                  style: const TextStyle(
                    color: AppColors.textMutedDark,
                    fontSize: AppSizes.p16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < sortedMonths.length; i++) ...[
                    _buildMonthHeader(sortedMonths[i], isOpen: i == 0),
                    const SizedBox(height: AppSizes.p16),
                    for (final spesa in speseGroupedByMonth[sortedMonths[i]]!)
                      _buildSpesaItem(context, spesa, currentUser),
                    if (i < sortedMonths.length - 1)
                      const SizedBox(height: AppSizes.p24),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSizes.p24),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: AppSizes.p36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p22),
        children: [
          _FilterChip(
            label: 'Tutte',
            color: AppColors.textMutedDark,
            active: _activeFilter == null,
            onTap: () => setState(() => _activeFilter = null),
          ),
          const SizedBox(width: AppSizes.p8),
          _FilterChip(
            label: _filterLabel(SpesaStatus.pagata),
            color: AppColors.balanceCredit,
            active: _activeFilter == SpesaStatus.pagata,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == SpesaStatus.pagata
                  ? null
                  : SpesaStatus.pagata;
            }),
          ),
          const SizedBox(width: AppSizes.p8),
          _FilterChip(
            label: _filterLabel(SpesaStatus.incompleta),
            color: AppColors.statusWarning,
            active: _activeFilter == SpesaStatus.incompleta,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == SpesaStatus.incompleta
                  ? null
                  : SpesaStatus.incompleta;
            }),
          ),
          const SizedBox(width: AppSizes.p8),
          _FilterChip(
            label: _filterLabel(SpesaStatus.nonPagata),
            color: AppColors.statusNegative,
            active: _activeFilter == SpesaStatus.nonPagata,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == SpesaStatus.nonPagata
                  ? null
                  : SpesaStatus.nonPagata;
            }),
          ),
        ],
      ),
    );
  }

  String _filterLabel(SpesaStatus status) => switch (status) {
    SpesaStatus.pagata => 'Pagata',
    SpesaStatus.incompleta => 'Incompleta',
    SpesaStatus.nonPagata => 'Non pagata',
  };

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p8,
        AppSizes.p16,
        AppSizes.p14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecondaryCtaButton(
            label: 'Pareggia i conti',
            color: MainCtaColors.turni,
            onPressed: () =>
                Navigator.of(context).pushNamed(PareggiaContiScreen.routeName),
          ),
          const SizedBox(height: AppSizes.p10),
          MainCtaButton(
            label: 'Inserisci nuova spesa',
            onPressed: () =>
                Navigator.of(context).pushNamed(InserisciSpesaScreen.routeName),
          ),
        ],
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
          color: AppColors.surfaceDarkMuted,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: AppSizes.p1,
              color: AppColors.borderMuted,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius8),
          ),
          shadows: [
            BoxShadow(
              color: AppColors.shadowOverlay,
              blurRadius: AppSizes.p4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALDO MESE - $monthName ${now.year}',
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: AppSizes.p18,
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
                        value: '€${saldo.toStringAsFixed(2)}',
                        valueColor: AppColors.textOnDark,
                      ),
                    ),
                    const VerticalDivider(
                      color: AppColors.textMutedSoft,
                      width: AppSizes.p8,
                      thickness: 1,
                    ),
                    Expanded(
                      child: _BalanceMetric(
                        label: 'Devi ricevere',
                        value: '€${credito.toStringAsFixed(2)}',
                        valueColor: AppColors.balanceCredit,
                      ),
                    ),
                    const VerticalDivider(
                      color: AppColors.textMutedSoft,
                      width: AppSizes.p8,
                      thickness: 1,
                    ),
                    Expanded(
                      child: _BalanceMetric(
                        label: 'Devi pagare',
                        value: '€${debito.toStringAsFixed(2)}',
                        valueColor: AppColors.balanceDebit,
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
          color: AppColors.textSubtle,
          fontSize: AppSizes.p18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSpesaItem(
    BuildContext context,
    Spesa spesa,
    AuthUser? currentUser,
  ) {
    final hasAnticipatore = spesaHasAnticipatore(spesa);
    final creatoreNome = spesa.creatoreNome.trim();
    final avatarInitials = creatoreNome.isNotEmpty
        ? _nameInitials(creatoreNome)
        : '';
    final status = spesaStatusFor(spesa, currentUser);
    final anticipatoreNome = hasAnticipatore ? creatoreNome : '';

    return Opacity(
      opacity: status == SpesaStatus.pagata ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.p16),
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).pushNamed(DettaglioSpesaAdminScreen.routeName, arguments: spesa.id),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SpesaAvatar(
                  initials: avatarInitials,
                  userId: spesa.creatoreId,
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleWithDate(
                        title: spesa.descrizione,
                        date: _formatDate(spesa.data),
                      ),
                      if (hasAnticipatore && anticipatoreNome.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.p3),
                        Text(
                          '$anticipatoreNome ha anticipato',
                          style: const TextStyle(
                            color: AppColors.textMutedDark,
                            fontSize: AppSizes.p12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.p5),
                      _SpesaStatusChip(status: status),
                      if (spesa.dataScadenza != null) ...[
                        const SizedBox(height: AppSizes.p4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: AppSizes.p11,
                              color: AppColors.keyYellow,
                            ),
                            const SizedBox(width: AppSizes.p3),
                            Text(
                              'Scade il ${_formatDate(spesa.dataScadenza!)}',
                              style: const TextStyle(
                                color: AppColors.keyYellow,
                                fontSize: AppSizes.p11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                Text(
                  '€${spesa.importo.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: AppSizes.p16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMutedDark,
                  size: AppSizes.p20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _nameInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
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

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p14,
          vertical: AppSizes.p0,
        ),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.18)
              : AppColors.surfaceDarkCard,
          borderRadius: BorderRadius.circular(AppSizes.radius18),
          border: Border.all(
            color: active ? color : AppColors.dividerDark,
            width: active ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : AppColors.textMutedDark,
            fontSize: AppSizes.p13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SpesaAvatar extends StatelessWidget {
  const _SpesaAvatar({required this.initials, this.userId = ''});

  final String initials;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final seed = userId.isNotEmpty ? userId : initials;
    final bgColor = seed.isNotEmpty
        ? userAvatarColorsForSeed(seed).background
        : AppColors.dividerDark;

    return Container(
      width: AppSizes.p40,
      height: AppSizes.p40,
      decoration: ShapeDecoration(color: bgColor, shape: const OvalBorder()),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? null
          : Text(
              initials,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p15,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _SpesaStatusChip extends StatelessWidget {
  const _SpesaStatusChip({required this.status});

  final SpesaStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      SpesaStatus.pagata => (
        'Pagata',
        AppColors.success,
        AppColors.balanceCredit,
      ),
      SpesaStatus.incompleta => (
        'Incompleta',
        AppColors.turniAssigneeMenuSurface,
        AppColors.statusWarning,
      ),
      SpesaStatus.nonPagata => (
        'Non pagata',
        AppColors.errorContainerDark,
        AppColors.statusNegative,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p7,
        vertical: AppSizes.p3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radius5),
        border: Border.all(
          color: fg.withValues(alpha: 0.5),
          width: AppSizes.p1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: AppSizes.p11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
          height: AppSizes.p38,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.textMutedSoft,
                fontSize: AppSizes.p14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor,
              fontSize: AppSizes.p22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyExpensesContent extends StatelessWidget {
  const _EmptyExpensesContent();

  @override
  Widget build(BuildContext context) {
    final selectedCasa = ActiveCasaScope.read(context).selectedCasa;
    final casaNome = selectedCasa?.nome.trim().isNotEmpty == true
        ? selectedCasa!.nome.trim()
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
          Text(
            'Spese',
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.brandAccent,
              fontSize: AppSizes.p40,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p20),
          Text(
            casaNome,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppColors.featureAccent,
              fontSize: AppSizes.p23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          Center(
            child: Container(
              width: AppSizes.p145,
              height: AppSizes.p145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.1),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/Icons/carrello_spesa.png',
                width: AppSizes.p100,
                height: AppSizes.p100,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          const Text(
            'Nessuna spesa registrata',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.p20),
          const Text(
            'Aggiungi la prima spesa della casa per\niniziare a dividere i costi con i\ncoinquilini',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMutedSoft,
              fontSize: AppSizes.p21,
              fontWeight: FontWeight.w500,
              height: 1.18,
            ),
          ),
          const SizedBox(height: AppSizes.p32),
          MainCtaButton(
            label: 'Inserisci spesa',
            onPressed: () =>
                Navigator.of(context).pushNamed(InserisciSpesaScreen.routeName),
          ),
        ],
      ),
    );
  }
}

class _TitleWithDate extends StatelessWidget {
  const _TitleWithDate({required this.title, required this.date});

  final String title;
  final String date;

  static const _titleStyle = TextStyle(
    color: AppColors.textOnDark,
    fontSize: AppSizes.p16,
    fontWeight: FontWeight.w600,
  );
  static const _dateStyle = TextStyle(
    color: AppColors.textMutedDark,
    fontSize: AppSizes.p11,
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    if (date.isEmpty) {
      return Text(
        title,
        style: _titleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final titlePainter = TextPainter(
          text: TextSpan(text: title, style: _titleStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: double.infinity);

        final datePainter = TextPainter(
          text: TextSpan(text: '  $date', style: _dateStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: double.infinity);

        final showDate =
            titlePainter.width + datePainter.width <= constraints.maxWidth;

        return Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: _titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showDate) ...[
              const SizedBox(width: AppSizes.p6),
              Text(date, style: _dateStyle),
            ],
          ],
        );
      },
    );
  }
}
