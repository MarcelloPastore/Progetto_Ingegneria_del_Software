import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_admin.dart';
import 'package:coincasa_app/features/spese/screens/inserisci_spesa_admin.dart';
import 'package:coincasa_app/features/spese/screens/pareggia_conti.dart';

final _speseProvider = FutureProvider.autoDispose.family<List<Spesa>, String>((
  ref,
  casaId,
) async {
  return ApiProvider.spese.list(casaId);
});

final _saldiProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, casaId) async {
      final saldo = await ApiProvider.spese.getSaldo(casaId);
      final credito = await ApiProvider.spese.getCreditoTot(casaId);
      final debito = await ApiProvider.spese.getDebitoTot(casaId);

      return {'saldo': saldo, 'credito': credito, 'debito': debito};
    });

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

  _SpesaStatus? _activeFilter;
  @override
  void initState() {
    super.initState();
    // Invalida i provider ad ogni apertura della schermata (anche via pushReplacementNamed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final casaId = ActiveCasaScope.read(context).selectedCasaId;
      if (casaId != null) {
        ref.invalidate(_speseProvider(casaId));
        ref.invalidate(_saldiProvider(casaId));
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
      ref.invalidate(_speseProvider(selectedCasaId));
      ref.invalidate(_saldiProvider(selectedCasaId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCasaController = ActiveCasaScope.read(context);
    final selectedCasaId = activeCasaController.selectedCasaId;

    if (selectedCasaId == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF151127),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final speseAsync = ref.watch(_speseProvider(selectedCasaId));
    final saldiAsync = ref.watch(_saldiProvider(selectedCasaId));

    // Aggiorna le cache ad ogni arrivo di dati freschi.
    speseAsync.whenData((s) => _cachedSpese = s);
    saldiAsync.whenData((s) => _cachedSaldi = s);

    // Usa la cache come fallback durante il caricamento.
    final effectiveSpese =
        speseAsync.maybeWhen(data: (s) => s, orElse: () => null) ??
        _cachedSpese;
    final effectiveSaldi =
        saldiAsync.maybeWhen(data: (s) => s, orElse: () => null) ??
        _cachedSaldi;
    final isLoading = speseAsync.isLoading && effectiveSpese == null;
    final hasSpese = (effectiveSpese?.isNotEmpty) ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF151127),
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
                      ),
                    // Indicatore sottile di refresh in background
                    if (speseAsync.isLoading && effectiveSpese != null)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
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
  ) {
    if (spese.isEmpty) {
      return const _EmptyExpensesContent();
    }

    // Apply filter
    final filtered = _activeFilter == null
        ? spese
        : spese
            .where((s) => _computeSpesaStatus(s) == _activeFilter)
            .toList();

    // Group by month
    final speseGroupedByMonth = <DateTime, List<Spesa>>{};
    for (final spesa in filtered) {
      final monthKey = DateTime(spesa.data.year, spesa.data.month);
      speseGroupedByMonth.putIfAbsent(monthKey, () => []);
      speseGroupedByMonth[monthKey]!.add(spesa);
    }

    for (final list in speseGroupedByMonth.values) {
      list.sort((a, b) => b.data.compareTo(a.data));
    }

    final sortedMonths = speseGroupedByMonth.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.p42),
            child: Center(
              child: Text(
                'Spese',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.brandAccent,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p24),

          // Monthly balance card
          if (saldi != null) _buildBalanceCard(saldi) else const SizedBox.shrink(),
          const SizedBox(height: AppSizes.p20),

          // Filter bar
          _buildFilterBar(),
          const SizedBox(height: AppSizes.p20),

          // Spese list or empty-filter message
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p22, vertical: AppSizes.p32),
              child: Center(
                child: Text(
                  'Nessuna spesa ${_filterLabel(_activeFilter!).toLowerCase()}.',
                  style: const TextStyle(
                    color: Color(0xFF908F8F),
                    fontSize: 16,
                    fontFamily: 'Inter',
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
                      _buildSpesaItem(context, spesa),
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
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p22),
        children: [
          _FilterChip(
            label: 'Tutte',
            color: const Color(0xFF908F8F),
            active: _activeFilter == null,
            onTap: () => setState(() => _activeFilter = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _filterLabel(_SpesaStatus.pagata),
            color: const Color(0xFF47CC5D),
            active: _activeFilter == _SpesaStatus.pagata,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == _SpesaStatus.pagata
                  ? null
                  : _SpesaStatus.pagata;
            }),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _filterLabel(_SpesaStatus.incompleta),
            color: const Color(0xFFFF9E45),
            active: _activeFilter == _SpesaStatus.incompleta,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == _SpesaStatus.incompleta
                  ? null
                  : _SpesaStatus.incompleta;
            }),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _filterLabel(_SpesaStatus.nonPagata),
            color: const Color(0xFFFF5252),
            active: _activeFilter == _SpesaStatus.nonPagata,
            onTap: () => setState(() {
              _activeFilter = _activeFilter == _SpesaStatus.nonPagata
                  ? null
                  : _SpesaStatus.nonPagata;
            }),
          ),
        ],
      ),
    );
  }

  String _filterLabel(_SpesaStatus status) => switch (status) {
    _SpesaStatus.pagata     => 'Pagata',
    _SpesaStatus.incompleta => 'Incompleta',
    _SpesaStatus.nonPagata  => 'Non pagata',
  };

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecondaryCtaButton(
            label: 'Pareggia i conti',
            color: MainCtaColors.turni,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(PareggiaContiScreen.routeName),
          ),
          const SizedBox(height: 10),
          MainCtaButton(
            label: 'Inserisci una nuova spesa',
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(InserisciSpesaScreen.routeName),
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
          color: const Color(0xFF2C2846),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFF807D7D)),
            borderRadius: BorderRadius.circular(AppSizes.radius8),
          ),
          shadows: [
            BoxShadow(
              color: const Color(0x3F000000),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALDO MESE - $monthName ${now.year}',
                style: const TextStyle(
                  color: Color(0xFFAFAEAE),
                  fontSize: 18,
                  fontFamily: 'Inter',
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
                        value: '€${saldo.toStringAsFixed(0)}',
                        valueColor: const Color(0xFFE1E1E1),
                      ),
                    ),
                    const VerticalDivider(
                      color: Color(0xFFB8B5C1),
                      width: AppSizes.p18,
                      thickness: 1,
                    ),
                    Expanded(
                      child: _BalanceMetric(
                        label: 'Devi ricevere',
                        value: '€${credito.toStringAsFixed(0)}',
                        valueColor: const Color(0xFF47CC5D),
                      ),
                    ),
                    const VerticalDivider(
                      color: Color(0xFFB8B5C1),
                      width: AppSizes.p18,
                      thickness: 1,
                    ),
                    Expanded(
                      child: _BalanceMetric(
                        label: 'Devi pagare',
                        value: '€${debito.toStringAsFixed(0)}',
                        valueColor: const Color(0xFFF14A4A),
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
          color: Color(0xFFAFAEAE),
          fontSize: 18,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSpesaItem(BuildContext context, Spesa spesa) {
    final hasAnticipatore = _spesaHasAnticipatore(spesa.raw);
    final creatoreNome = spesa.creatoreNome.trim();
    final avatarInitials = creatoreNome.isNotEmpty ? _nameInitials(creatoreNome) : '';
    final status = _computeSpesaStatus(spesa);
    final anticipatoreNome = hasAnticipatore ? creatoreNome : '';
    final firstNameAnticipatore = anticipatoreNome.split(RegExp(r'\s+')).first;

    return Opacity(
      opacity: status == _SpesaStatus.pagata ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.p16),
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(
            DettaglioSpesaAdminScreen.routeName,
            arguments: spesa.id,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SpesaAvatar(initials: avatarInitials, userId: spesa.creatoreId),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spesa.descrizione,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasAnticipatore && anticipatoreNome.isNotEmpty
                            ? '${_formatDate(spesa.data)} · $firstNameAnticipatore ha anticipato'
                            : _formatDate(spesa.data),
                        style: const TextStyle(
                          color: Color(0xFF908F8F),
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _SpesaStatusChip(status: status),
                      if (spesa.dataScadenza != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: Color(0xFFFFD31A),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Scade il ${_formatDate(spesa.dataScadenza!)}',
                              style: const TextStyle(
                                color: Color(0xFFFFD31A),
                                fontSize: 11,
                                fontFamily: 'Inter',
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
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF908F8F),
                  size: AppSizes.p20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _SpesaStatus _computeSpesaStatus(Spesa spesa) {
    final nonEsclusi = spesa.partecipanti
        .where((p) => p['escluso'] != true)
        .toList();
    if (nonEsclusi.isEmpty) return _SpesaStatus.nonPagata;

    bool isPaid(Map<String, dynamic> p) =>
        p['pagato'] == true || p['pagata'] == true || p['saldato'] == true;

    if (nonEsclusi.every(isPaid)) return _SpesaStatus.pagata;

    for (final p in nonEsclusi) {
      if (_isCurrentUserPartecipante(p)) {
        return isPaid(p) ? _SpesaStatus.incompleta : _SpesaStatus.nonPagata;
      }
    }
    return _SpesaStatus.nonPagata;
  }

  bool _isCurrentUserPartecipante(Map<String, dynamic> p) {
    final userId = ApiProvider.client.currentUserId?.trim();
    final userEmail = ApiProvider.client.currentUserEmail?.trim().toLowerCase();

    final utente = p['utente'];
    if (utente is Map) {
      if (userId != null &&
          (utente['id']?.toString() == userId ||
              utente['utenteId']?.toString() == userId)) {
        return true;
      }
      if (userEmail != null &&
          utente['email']?.toString().toLowerCase() == userEmail) {
        return true;
      }
    }
    if (userId != null &&
        (p['utenteId']?.toString() == userId ||
            p['idUtente']?.toString() == userId)) {
      return true;
    }
    if (userEmail != null && p['email']?.toString().toLowerCase() == userEmail) {
      return true;
    }
    return false;
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

  String _nameInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.18)
              : const Color(0xFF1E1A2D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? color : const Color(0xFF3A3555),
            width: active ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : const Color(0xFF908F8F),
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stato spesa — 3 livelli dal punto di vista del current user
// ---------------------------------------------------------------------------

enum _SpesaStatus { pagata, incompleta, nonPagata }

class _SpesaAvatar extends StatelessWidget {
  const _SpesaAvatar({required this.initials, this.userId = ''});

  final String initials;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final seed = userId.isNotEmpty ? userId : initials;
    final bgColor = seed.isNotEmpty
        ? userAvatarColorsForSeed(seed).background
        : const Color(0xFF3A3850);

    return Container(
      width: 40,
      height: 40,
      decoration: ShapeDecoration(color: bgColor, shape: const OvalBorder()),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? null
          : Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _SpesaStatusChip extends StatelessWidget {
  const _SpesaStatusChip({required this.status});

  final _SpesaStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _SpesaStatus.pagata => (
          'Pagata',
          const Color(0xFF0A2D1A),
          const Color(0xFF47CC5D),
        ),
      _SpesaStatus.incompleta => (
          'Incompleta',
          const Color(0xFF2E1800),
          const Color(0xFFFF9E45),
        ),
      _SpesaStatus.nonPagata => (
          'Non pagata',
          const Color(0xFF2D0A0A),
          const Color(0xFFFF5252),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: fg.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontFamily: 'Inter',
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
          height: 38,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFFAAA7B2),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: 23,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyExpensesContent extends StatelessWidget {
  const _EmptyExpensesContent();

  Future<Casa?> _loadActiveCasa(BuildContext context) async {
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }
    return activeCasaController.resolveCasa(caseUtente);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Casa?>(
      future: _loadActiveCasa(context),
      builder: (context, snapshot) {
        final casaNome = snapshot.data?.nome.trim().isNotEmpty == true
            ? snapshot.data!.nome.trim()
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
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSizes.p20),
              Text(
                casaNome,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Color(0xFF996CFA),
                  fontSize: 23,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSizes.p4),
              Center(
                child: Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2D9E6E).withValues(alpha: 0.1),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/Icons/carrello_spesa.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p24),
              const Text(
                'Nessuna spesa registrata',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF6F6F6),
                  fontSize: 23,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSizes.p20),
              const Text(
                'Aggiungi la prima spesa della casa per\niniziare a dividere i costi con i\ncoinquilini',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB1B1B1),
                  fontSize: 21,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: AppSizes.p32),
              MainCtaButton(
                label: 'Inserisci spesa',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(InserisciSpesaScreen.routeName),
              ),
            ],
          ),
        );
      },
    );
  }
}
