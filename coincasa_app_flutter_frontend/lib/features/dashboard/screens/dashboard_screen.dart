import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/dashboard/house_health_section.dart';
import 'package:coincasa_app/features/icone_fab.dart';

// Riferimento globale per il file all'utente corrente per facilitare l'accesso alle variabili di sessione
final _me = ApiProvider.client;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _dashboardDataFuture;
  late ActiveCasaController _activeCasaController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    _activeCasaController = ActiveCasaScope.read(context);
    _dashboardDataFuture = _loadDashboardData();
    _initialized = true;
  }

  Future<_DashboardData> _loadDashboardData() async {
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

    setState(() {
      _activeCasaController.selectCasa(casaId);
      _dashboardDataFuture = _loadDashboardData();
    });
  }

  List<HouseHealthBadgeData> _buildHouseHealthBadges(List<Turno> turni) {
    final badges = turni
        .map(
          (turno) => HouseHealthBadgeData(
            caption: _formatHouseHealthCaption(turno.titolo),
            lastCleaningDate: turno.dataUltimaPuliziaEffettiva,
          ),
        )
        .where((badge) => badge.caption.trim().isNotEmpty)
        .toList(growable: false);

    badges.sort((a, b) {
      final aDate = a.lastCleaningDate;
      final bDate = b.lastCleaningDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return badges.take(4).toList(growable: false);
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
                    const _EmptyProblemsSection(),
                    const SizedBox(height: AppSizes.p28),
                    _TodayTurnSection(
                      dashboardDataFuture: _dashboardDataFuture,
                    ),
                    const SizedBox(height: AppSizes.p28),
                    _EmptyCalendarSection(
                      dashboardDataFuture: _dashboardDataFuture,
                    ),
                  ],
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
          firstName: _me.currentUserFirstName,
          lastName: _me.currentUserLastName,
          fullName: _me.currentUserDisplayName,
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gestione account non ancora implementata.'),
              ),
            );
          },
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

class _TodayTurnSection extends StatelessWidget {
  const _TodayTurnSection({required this.dashboardDataFuture});

  final Future<_DashboardData> dashboardDataFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('TURNO DI OGGI'),
        const SizedBox(height: AppSizes.p10),
        FutureBuilder<_DashboardData>(
          future: dashboardDataFuture,
          builder: (context, snapshot) {
            final turniOggi = snapshot.data?.turniOggi ?? const <Turno>[];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null;
            final turno = turniOggi.isNotEmpty ? turniOggi.first : null;

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
                child: _StatusRow(
                  title: isLoading
                      ? 'Caricamento turno...'
                      : turno?.titolo ?? 'Nessuna pulizia da fare!',
                  status: '',
                  titleColor: AppColors.textOnDark,
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
                                final hasTurno =
                                    inMonth && _hasTurno(date, turni);

                                return _DashboardCalendarDay(
                                  day: inMonth ? '${date.day}' : '',
                                  hasTurno: hasTurno,
                                );
                              },
                            );
                          },
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

  static bool _hasTurno(DateTime date, List<Turno> turni) {
    return turni.any((turno) {
      final turnoDate = turno.dataProssimaPulizia;
      return turnoDate != null &&
          turnoDate.year == date.year &&
          turnoDate.month == date.month &&
          turnoDate.day == date.day;
    });
  }
}

class _DashboardCalendarDay extends StatelessWidget {
  const _DashboardCalendarDay({required this.day, required this.hasTurno});

  final String day;
  final bool hasTurno;

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
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: hasTurno ? AppColors.brandAccent : AppColors.transparent,
            shape: BoxShape.circle,
          ),
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
