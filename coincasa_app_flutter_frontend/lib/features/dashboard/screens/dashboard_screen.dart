import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:coincasa_app/app.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/dashboard/house_health_section.dart';
import 'package:coincasa_app/core/widgets/dashboard/open_problems_section.dart';
import 'package:coincasa_app/features/icone_fab.dart';

// Riferimento globale per il file all'utente corrente per facilitare l'accesso alle variabili di sessione
final _me = ApiProvider.client;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  late Future<_DashboardData> _dashboardDataFuture;
  late ActiveCasaController _activeCasaController;
  bool _initialized = false;

  /// Cache statica: sopravvive alla distruzione del widget (pushReplacementNamed).
  static _DashboardData? _cachedData;
  bool _isBackgroundRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Avvia subito un aggiornamento in background dopo il primo frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _triggerRefresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _activeCasaController = ActiveCasaScope.read(context);
    // Registra il RouteObserver ad ogni chiamata (sicuro: unsubscribe avviene in dispose)
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
    // Prima inizializzazione: usa la cache per mostrare subito i dati (se disponibili),
    // altrimenti avvia il caricamento da rete.
    if (!_initialized) {
      if (_cachedData != null) {
        _dashboardDataFuture = Future.value(_cachedData);
      } else {
        _dashboardDataFuture = _fetchFromNetwork().then((data) {
          _cachedData = data;
          return data;
        });
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Ricarica i dati ogni volta che si torna a questa schermata.
  @override
  void didPopNext() {
    super.didPopNext();
    _triggerRefresh();
  }

  /// Stale-while-revalidate: mostra subito i dati in cache e aggiorna silenziosamente in background.
  void _triggerRefresh() {
    if (_cachedData != null) {
      setState(() {
        _isBackgroundRefreshing = true;
        _dashboardDataFuture = Future.value(_cachedData!);
      });
      _fetchFromNetwork().then((fresh) {
        if (!mounted) return;
        _cachedData = fresh;
        setState(() {
          _dashboardDataFuture = Future.value(fresh);
          _isBackgroundRefreshing = false;
        });
      }).catchError((_) {
        if (mounted) setState(() => _isBackgroundRefreshing = false);
      });
    } else {
      // Prima visita senza cache: se già in caricamento da didChangeDependencies non fare nulla.
      if (_initialized) return;
      setState(() {
        _dashboardDataFuture = _fetchFromNetwork().then((data) {
          _cachedData = data;
          return data;
        });
      });
    }
  }

  /// Fetch effettivo dei dati da rete.
  Future<_DashboardData> _fetchFromNetwork() async {
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return const _DashboardData(
        nomeCasa: 'Nessuna casa',
        caseUtente: [],
        casaSelezionataId: null,
      );
    }

    final casa = _activeCasaController.resolveCasa(caseUtente);
    final nomeCasa = _formatNomeCasa(casa);
    final displayName = nomeCasa.isEmpty ? 'Casa senza nome' : nomeCasa;
    final turniFuture = ApiProvider.turni.list(casa.id);
    final turniOggiFuture = ApiProvider.turni.listOggi(casa.id);

    final amounts = await Future.wait<double>([
      ApiProvider.spese.getSaldo(casa.id),
      ApiProvider.spese.getCreditoTot(casa.id),
      ApiProvider.spese.getDebitoTot(casa.id),
    ]);
    final turni = await turniFuture;
    final turniOggi = await turniOggiFuture;
    final spese = await ApiProvider.spese.list(casa.id);
    final houseHealthBadges = _buildHouseHealthBadges(turni);

    return _DashboardData(
      nomeCasa: displayName,
      caseUtente: caseUtente,
      casaSelezionataId: casa.id,
      saldo: amounts[0],
      credito: amounts[1],
      debito: amounts[2],
      turni: turni,
      turniOggi: turniOggi,
      spese: spese,
      houseHealthBadges: houseHealthBadges,
    );
  }

  String _formatNomeCasa(Casa casa) {
    final nome = casa.nome.trim();
    if (nome.isEmpty) {
      return '';
    }

    return nome.toLowerCase().startsWith('casa ') ? nome : 'Casa $nome';
  }

  void _selectCasa(String casaId) {
    if (_activeCasaController.selectedCasaId == casaId) {
      return;
    }

    _activeCasaController.selectCasa(casaId);
    _cachedData = null; // Invalida la cache al cambio di casa
    _triggerRefresh();
  }

  List<HouseHealthBadgeData> _buildHouseHealthBadges(List<Turno> turni) {
    final badges = turni
        .map(
          (turno) => HouseHealthBadgeData(
            caption: _formatHouseHealthCaption(turno.titolo),
            lastCleaningDate: turno.dataUltimaPuliziaEffettiva,
            nextCleaningDate: turno.dataProssimaPulizia,
            cadenzaGiorni: turno.cadenzaGiorni,
            completato: turno.completato,
          ),
        )
        .where((badge) => badge.caption.trim().isNotEmpty)
        .toList(growable: true);

    // Ordina per priorità cromatica: grigio (0) → rosso (1) → arancione (2) → verde (3)
    badges.sort((a, b) => _badgeColorOrder(a).compareTo(_badgeColorOrder(b)));

    return badges;
  }

  /// Calcola la priorità di ordinamento in base al colore dell'anello.
  /// Deve rispecchiare la stessa logica di _HealthBadge._color.
  static int _badgeColorOrder(HouseHealthBadgeData badge) {
    final nextDate = badge.nextCleaningDate;
    if (nextDate == null) return 0; // grigio

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final nextOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final daysUntil = nextOnly.difference(todayOnly).inDays;

    if (daysUntil < -3) return 0; // grigio
    if (!badge.completato && daysUntil >= -3 && daysUntil <= 0) return 1; // rosso
    // Soglia arancione proporzionale alla cadenza, identica a _HealthBadge._color
    final orangeThreshold = badge.cadenzaGiorni ~/ 3;
    if (daysUntil <= orangeThreshold) return 2; // arancione
    return 3; // verde
  }

  String _formatHouseHealthCaption(String title) {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      return 'Turno';
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p10,
                  AppSizes.p16,
                  AppSizes.p10,
                  AppSizes.p110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EmptyDashboardHeader(
                      dashboardDataFuture: _dashboardDataFuture,
                      onCasaChanged: _selectCasa,
                    ),
                    const SizedBox(height: AppSizes.p12),
                    _EmptyBalanceCard(
                      dashboardDataFuture: _dashboardDataFuture,
                    ),
                    const SizedBox(height: AppSizes.p28),
                    _HouseHealthSection(
                      dashboardDataFuture: _dashboardDataFuture,
                    ),
                    const SizedBox(height: AppSizes.p28),
                    const _EmptyMessageSection(
                      title: 'PROSSIME SCADENZE',
                      message: 'Nessuna scadenza presente...',
                      height: 150,
                      routeName: '/scadenze',
                    ),
                    const SizedBox(height: AppSizes.p28),
                    const OpenProblemsSection(),
                    const SizedBox(height: AppSizes.p28),
                    _TodayTurnSection(
                      dashboardDataFuture: _dashboardDataFuture,
                      onRefresh: _triggerRefresh,
                    ),
                    const SizedBox(height: AppSizes.p28),
                    _EmptyCalendarSection(
                      dashboardDataFuture: _dashboardDataFuture,
                    ),
                  ],
                ),
              ),
              if (_isBackgroundRefreshing)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              Positioned(
                right: AppSizes.p10,
                bottom: AppSizes.p24,
                child: FloatingActionButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const DashboardCreatePopup(),
                    );
                  },
                  backgroundColor: AppColors.brandAccent,
                  elevation: AppSizes.p6,
                  child: const Icon(
                    Icons.add,
                    size: AppSizes.p38,
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.nomeCasa,
    required this.caseUtente,
    required this.casaSelezionataId,
    this.saldo,
    this.credito,
    this.debito,
    this.turni = const [],
    this.turniOggi = const [],
    this.spese = const [],
    this.houseHealthBadges = const [],
  });

  final String nomeCasa;
  final List<Casa> caseUtente;
  final String? casaSelezionataId;
  final double? saldo;
  final double? credito;
  final double? debito;
  final List<Turno> turni;
  final List<Turno> turniOggi;
  final List<Spesa> spese;
  final List<HouseHealthBadgeData> houseHealthBadges;
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar({required this.future, this.radius = AppSizes.p23});

  final Future<_DashboardData> future;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: future,
      builder: (context, snapshot) {
        return UserAvatar(
          radius: radius,
          userId: _me.currentUserAvatarSeed,
          username: _me.currentUserUsername,
        );
      },
    );
  }
}

class _EmptyDashboardHeader extends StatelessWidget {
  const _EmptyDashboardHeader({
    required this.dashboardDataFuture,
    required this.onCasaChanged,
  });

  final Future<_DashboardData> dashboardDataFuture;
  final ValueChanged<String> onCasaChanged;

  String _formatNomeCasa(Casa casa) {
    final nome = casa.nome.trim();
    if (nome.isEmpty) {
      return 'Casa senza nome';
    }

    return nome.toLowerCase().startsWith('casa ') ? nome : 'Casa $nome';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/account'),
          customBorder: const CircleBorder(),
          child: _CurrentUserAvatar(
            future: dashboardDataFuture,
            radius: AppSizes.p23,
          ),
        ),
        const SizedBox(width: AppSizes.p14),
        Expanded(
          child: FutureBuilder<_DashboardData>(
            future: dashboardDataFuture,
            builder: (context, snapshot) {
              final nomeCasa = switch (snapshot.connectionState) {
                ConnectionState.none ||
                ConnectionState.waiting => 'Caricamento...',
                _ when snapshot.hasError => 'Casa non disponibile',
                _ => snapshot.data?.nomeCasa ?? 'Nessuna casa',
              };
              final data = snapshot.data;

              if (data != null && data.caseUtente.length > 1) {
                return _HouseSelector(
                  caseUtente: data.caseUtente,
                  selectedCasaId: data.casaSelezionataId,
                  formatNomeCasa: _formatNomeCasa,
                  onCasaChanged: onCasaChanged,
                );
              }

              return Text(
                nomeCasa,
                style: AppTextStyles.dashboardHeaderTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
        const SizedBox(width: AppSizes.p14),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/casa'),
          customBorder: const CircleBorder(),
          child: const CircleAvatar(
            radius: AppSizes.p23,
            backgroundColor: AppColors.brandSecondary,
            child: Image(
              image: AssetImage('assets/Icons/Icona_dashboard.png'),
              width: AppSizes.p28,
              height: AppSizes.p28,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _HouseSelector extends StatelessWidget {
  const _HouseSelector({
    required this.caseUtente,
    required this.selectedCasaId,
    required this.formatNomeCasa,
    required this.onCasaChanged,
  });

  final List<Casa> caseUtente;
  final String? selectedCasaId;
  final String Function(Casa casa) formatNomeCasa;
  final ValueChanged<String> onCasaChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: AppSizes.p8,
            offset: Offset(0, AppSizes.p2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedCasaId,
            isExpanded: true,
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.brandSecondary,
            ),
            dropdownColor: AppColors.surface,
            style: AppTextStyles.dashboardHeaderTitle,
            selectedItemBuilder: (context) {
              return caseUtente.map((casa) {
                return Center(
                  child: Text(
                    formatNomeCasa(casa),
                    style: AppTextStyles.dashboardHeaderTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            items: caseUtente.map((casa) {
              return DropdownMenuItem<String>(
                value: casa.id,
                child: Text(
                  formatNomeCasa(casa),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onCasaChanged(value);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyBalanceCard extends StatelessWidget {
  const _EmptyBalanceCard({required this.dashboardDataFuture});

  final Future<_DashboardData> dashboardDataFuture;

  String _formatAmount(double? value, {bool showPlus = false}) {
    if (value == null) {
      return '\u20AC0';
    }

    final rounded = value.toStringAsFixed(2);
    final normalized = rounded.endsWith('.00')
        ? rounded.substring(0, rounded.length - 3)
        : rounded;
    final prefix = value < 0
        ? '-'
        : showPlus && value > 0
        ? '+'
        : '';

    return '$prefix\u20AC${normalized.replaceFirst('-', '')}';
  }

  Color _saldoColor(double? saldo) {
    if (saldo == null || saldo >= 0) {
      return AppColors.statusPositive;
    }

    return AppColors.statusNegative;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/spese'),
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Column(
        children: [
          Text(
            'IL TUO SALDO',
            style: AppTextStyles.dashboardHeaderSubtitle.copyWith(
              color: AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p10),
          FutureBuilder<_DashboardData>(
            future: dashboardDataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final saldo = data?.saldo;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.p18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkElevated,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowStrong,
                      blurRadius: AppSizes.p8,
                      offset: Offset(0, AppSizes.p5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p18,
                  AppSizes.p10,
                  AppSizes.p14,
                  AppSizes.p18,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: AppSizes.p30),
                        Expanded(
                          child: Text(
                            'Totale',
                            style: AppTextStyles.dashboardBalanceTitle.copyWith(
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/Icons/Arrow up-right.svg',
                          width: AppSizes.p30,
                          height: AppSizes.p30,
                          colorFilter: const ColorFilter.mode(
                            AppColors.brandAccent,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatAmount(saldo),
                      style: AppTextStyles.dashboardBalanceAmount.copyWith(
                        color: _saldoColor(saldo),
                        fontSize: 25,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p18),
                    Row(
                      children: [
                        Expanded(
                          child: _BalanceMetric(
                            label: 'Da ricevere',
                            value: _formatAmount(data?.credito, showPlus: true),
                            valueColor: AppColors.statusPositive,
                            align: CrossAxisAlignment.center,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: AppSizes.p42,
                          color: AppColors.dividerOnDark,
                        ),
                        Expanded(
                          child: _BalanceMetric(
                            label: 'Devi pagare',
                            value: _formatAmount(data?.debito),
                            valueColor: AppColors.statusNegative,
                            align: CrossAxisAlignment.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.align,
  });

  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppTextStyles.dashboardCardLabel.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.p10),
        Text(
          value,
          style: AppTextStyles.dashboardCardPositiveValue.copyWith(
            color: valueColor,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}

class _EmptyMessageSection extends StatelessWidget {
  const _EmptyMessageSection({
    required this.title,
    required this.message,
    required this.height,
    this.routeName,
  });

  final String title;
  final String message;
  final double height;
  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CenteredSectionTitle(title),
        const SizedBox(height: AppSizes.p10),
        InkWell(
          onTap: routeName == null
              ? null
              : () => Navigator.of(context).pushNamed(routeName!),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
            ),
            alignment: Alignment.center,
            child: Text(
              message,
              style: AppTextStyles.dashboardCardSubtitleOnDark.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _HouseHealthSection extends StatelessWidget {
  const _HouseHealthSection({required this.dashboardDataFuture});

  final Future<_DashboardData> dashboardDataFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: dashboardDataFuture,
      builder: (context, snapshot) {
        final badges = snapshot.data?.houseHealthBadges ?? const [];
        return HouseHealthSection(badges: badges);
      },
    );
  }
}

class _EmptyProblemsSection extends StatelessWidget {
  const _EmptyProblemsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('PROBLEMI APERTI'),
        const SizedBox(height: AppSizes.p10),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/problemi'),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: Container(
            height: 246,
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowStrong,
                  blurRadius: AppSizes.p8,
                  offset: Offset(0, AppSizes.p5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p10,
              AppSizes.p15,
              AppSizes.p20,
              AppSizes.p17,
            ),
            child: Column(
              children: [
                const _StatusRow(
                  title: 'Nessun problema',
                  status: 'la casa sta bene!',
                  titleColor: AppColors.statusPositive,
                ),
                const Spacer(),
                Text(
                  'Vedi tutti',
                  style: AppTextStyles.dashboardSectionLink.copyWith(
                    color: AppColors.brandAccent,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayTurnSection extends StatefulWidget {
  const _TodayTurnSection({
    required this.dashboardDataFuture,
    required this.onRefresh,
  });

  final Future<_DashboardData> dashboardDataFuture;
  final VoidCallback onRefresh;

  @override
  State<_TodayTurnSection> createState() => _TodayTurnSectionState();
}

class _TodayTurnSectionState extends State<_TodayTurnSection> {
  final Set<String> _completingIds = {};

  Future<void> _completaTurno(String casaId, String turnoId) async {
    setState(() {
      _completingIds.add(turnoId);
    });
    try {
      await ApiProvider.turni.completa(casaId, turnoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turno completato con successo!')),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile completare il turno. Riprova.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _completingIds.remove(turnoId);
        });
      }
    }
  }

  Widget _buildCompleteButton(String casaId, Turno turno) {
    final isCompleting = _completingIds.contains(turno.id);
    if (isCompleting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.lockOrange),
        ),
      );
    }
    return SizedBox(
      height: 38,
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
          onPressed: () => _completaTurno(casaId, turno.id),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Completa',
            style: TextStyle(
              color: AppColors.lockOrange,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTurnoRow(Turno turno, String? casaId, bool isLast) {
    final isCurrentAssignee =
        casaId != null && turno.assegnatarioId == _me.currentUserId;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.p12),
      child: Row(
        children: [
          UserAvatar(
            radius: 24,
            userId: turno.assegnatarioId,
            username: turno.assegnatarioNome.isNotEmpty ? turno.assegnatarioNome : null,
            fallback: '?',
          ),
          const SizedBox(width: AppSizes.p14),
          Expanded(
            child: Text(
              turno.titolo,
              style: AppTextStyles.dashboardCardTitleOnDark.copyWith(
                color: AppColors.textOnDark,
                fontSize: 18,
              ),
            ),
          ),
          if (isCurrentAssignee) ...[
            const SizedBox(width: AppSizes.p8),
            _buildCompleteButton(casaId, turno),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('TURNI DI OGGI'),
        const SizedBox(height: AppSizes.p10),
        FutureBuilder<_DashboardData>(
          future: widget.dashboardDataFuture,
          builder: (context, snapshot) {
            final turniOggi = snapshot.data?.turniOggi ?? const <Turno>[];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null;
            final casaId = snapshot.data?.casaSelezionataId;

            return InkWell(
              onTap: () => Navigator.of(context).pushNamed('/turni'),
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkElevated,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowStrong,
                      blurRadius: AppSizes.p8,
                      offset: Offset(0, AppSizes.p5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p14,
                  AppSizes.p16,
                  AppSizes.p20,
                  AppSizes.p16,
                ),
                child: isLoading
                    ? Row(
                        children: [
                          Container(
                            width: AppSizes.p48,
                            height: AppSizes.p48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceDark,
                            ),
                          ),
                          const SizedBox(width: AppSizes.p14),
                          Expanded(
                            child: Text(
                              'Caricamento turno...',
                              style: AppTextStyles.dashboardCardTitleOnDark
                                  .copyWith(
                                    color: AppColors.textOnDark,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : turniOggi.isEmpty
                    ? Row(
                        children: [
                          Container(
                            width: AppSizes.p48,
                            height: AppSizes.p48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.statusPositive,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppColors.statusPositive,
                              size: AppSizes.p28,
                            ),
                          ),
                          const SizedBox(width: AppSizes.p14),
                          Expanded(
                            child: Text(
                              'Nessuna pulizia da fare!',
                              style: AppTextStyles.dashboardCardTitleOnDark
                                  .copyWith(
                                    color: AppColors.textOnDark,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: List.generate(turniOggi.length, (i) {
                          return _buildTurnoRow(
                            turniOggi[i],
                            casaId,
                            i == turniOggi.length - 1,
                          );
                        }),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}


class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.title,
    required this.status,
    required this.titleColor,
  });

  final String title;
  final String status;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSizes.p48,
          height: AppSizes.p48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.statusPositive, width: 2),
          ),
          child: const Icon(
            Icons.check,
            color: AppColors.statusPositive,
            size: AppSizes.p28,
          ),
        ),
        const SizedBox(width: AppSizes.p14),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.dashboardCardTitleOnDark.copyWith(
              color: titleColor,
              fontSize: 18,
            ),
          ),
        ),
        Text(
          status,
          style: AppTextStyles.dashboardListStatus.copyWith(
            color: AppColors.statusPositive,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _EmptyCalendarSection extends StatelessWidget {
  const _EmptyCalendarSection({required this.dashboardDataFuture});

  final Future<_DashboardData> dashboardDataFuture;

  static const List<String> _weekDays = [
    'Lu',
    'Ma',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom',
  ];
  static const List<String> _monthNames = [
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('CALENDARIO SCADENZE'),
        const SizedBox(height: AppSizes.p10),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/scadenze'),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.surfaceDark),
              child: Column(
                children: [
                  Container(
                    height: AppSizes.p48,
                    color: AppColors.brandSecondary,
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[month.month - 1],
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.p20,
                      AppSizes.p18,
                      AppSizes.p20,
                      AppSizes.p30,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: _weekDays
                              .map(
                                (day) => Expanded(
                                  child: Text(
                                    day,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles
                                        .dashboardCalendarWeekday
                                        .copyWith(
                                          color: AppColors.textOnDark,
                                          fontSize: 13,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: AppSizes.p16),
                        FutureBuilder<_DashboardData>(
                          future: dashboardDataFuture,
                          builder: (context, snapshot) {
                            final turni = snapshot.data?.turni ?? const [];
                            final spese = snapshot.data?.spese ?? const [];
                            final days = _buildGridDays(month);

                            return GridView.builder(
                              itemCount: days.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    mainAxisSpacing: AppSizes.p12,
                                    crossAxisSpacing: AppSizes.p12,
                                    mainAxisExtent: 44,
                                  ),
                              itemBuilder: (context, index) {
                                final date = days[index];
                                final inMonth = date.month == month.month;
                                final markers = inMonth
                                    ? _markersForDate(date, turni, spese)
                                    : const <Color>[];

                                return _DashboardCalendarDay(
                                  day: inMonth ? '${date.day}' : '',
                                  markers: markers,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.p20),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendItem(
                              color: AppColors.statusInfo,
                              label: 'Turni',
                            ),
                            SizedBox(width: AppSizes.p20),
                            _LegendItem(
                              color: AppColors.statusNegative,
                              label: 'Scadenze',
                            ),
                            SizedBox(width: AppSizes.p20),
                            _LegendItem(
                              color: AppColors.keyYellow,
                              label: 'Spese',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static List<DateTime> _buildGridDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final start = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  static List<Color> _markersForDate(
    DateTime date,
    List<Turno> turni,
    List<Spesa> spese,
  ) {
    final colors = <Color>[];
    for (final turno in turni) {
      final turnoDate = turno.dataProssimaPulizia;
      if (turnoDate != null &&
          turnoDate.year == date.year &&
          turnoDate.month == date.month &&
          turnoDate.day == date.day) {
        colors.add(AppColors.statusInfo);
        if (colors.length == 4) break;
      }
    }
    for (final spesa in spese) {
      final scadenza = spesa.dataScadenza;
      if (scadenza != null &&
          scadenza.year == date.year &&
          scadenza.month == date.month &&
          scadenza.day == date.day) {
        if (!colors.contains(AppColors.keyYellow)) {
          colors.add(AppColors.keyYellow);
        }
        break;
      }
    }
    return colors;
  }
}

class _DashboardCalendarDay extends StatelessWidget {
  const _DashboardCalendarDay({required this.day, required this.markers});

  final String day;
  final List<Color> markers;

  @override
  Widget build(BuildContext context) {
    if (day.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day,
          textAlign: TextAlign.center,
          style: AppTextStyles.dashboardCalendarDay.copyWith(
            color: AppColors.textOnDark,
            fontSize: 14,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (markers.isEmpty)
              const SizedBox(width: 7, height: 7)
            else
              ...markers.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(left: e.key == 0 ? 0 : 2),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CenteredSectionTitle extends StatelessWidget {
  const _CenteredSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.dashboardSectionTitle.copyWith(
        color: AppColors.textMuted,
        fontSize: 18,
        letterSpacing: 0,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.p6),
        Text(
          label,
          style: AppTextStyles.dashboardLegendLabel.copyWith(
            color: AppColors.textOnDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
