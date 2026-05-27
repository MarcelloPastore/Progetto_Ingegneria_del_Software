import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<String> _nomeCasaFuture;

  @override
  void initState() {
    super.initState();
    _nomeCasaFuture = _loadNomeCasa();
  }

  Future<String> _loadNomeCasa() async {
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return 'Nessuna casa';
    }

    final casa = caseUtente.first;
    final nomeCasa = _formatNomeCasa(casa);
    return nomeCasa.isEmpty ? 'Casa senza nome' : nomeCasa;
  }

  String _formatNomeCasa(Casa casa) {
    final nome = casa.nome.trim();
    if (nome.isEmpty) {
      return '';
    }

    return nome.toLowerCase().startsWith('casa ') ? nome : 'Casa $nome';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      bottomNavigationBar: const _DashboardBottomNav(),
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
                  _EmptyDashboardHeader(nomeCasaFuture: _nomeCasaFuture),
                  const SizedBox(height: AppSizes.p12),
                  const _EmptyBalanceCard(),
                  const SizedBox(height: AppSizes.p28),
                  const _EmptyMessageSection(
                    title: 'SALUTE DELLA CASA',
                    message: 'Nessun turno creato...',
                    height: 126,
                  ),
                  const SizedBox(height: AppSizes.p28),
                  const _EmptyMessageSection(
                    title: 'PROSSIME SCADENZE',
                    message: 'Nessuna scadenza presente...',
                    height: 150,
                  ),
                  const SizedBox(height: AppSizes.p28),
                  const _EmptyProblemsSection(),
                  const SizedBox(height: AppSizes.p28),
                  const _EmptyTodayTurnSection(),
                  const SizedBox(height: AppSizes.p28),
                  const _EmptyCalendarSection(),
                ],
              ),
            ),
            Positioned(
              right: AppSizes.p10,
              bottom: AppSizes.p24,
              child: FloatingActionButton(
                onPressed: () {},
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
    );
  }
}

class _EmptyDashboardHeader extends StatelessWidget {
  const _EmptyDashboardHeader({required this.nomeCasaFuture});

  final Future<String> nomeCasaFuture;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: AppSizes.p23,
          backgroundColor: AppColors.surfaceTint,
          child: Image(
            image: AssetImage('assets/Icons/Profilo_utente_icona.png'),
            width: AppSizes.p27,
            height: AppSizes.p27,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: AppSizes.p14),
        Expanded(
          child: FutureBuilder<String>(
            future: nomeCasaFuture,
            builder: (context, snapshot) {
              final nomeCasa = switch (snapshot.connectionState) {
                ConnectionState.none ||
                ConnectionState.waiting => 'Caricamento...',
                _ when snapshot.hasError => 'Casa non disponibile',
                _ => snapshot.data ?? 'Nessuna casa',
              };

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
        const CircleAvatar(
          radius: AppSizes.p23,
          backgroundColor: AppColors.brandSecondary,
          child: Image(
            image: AssetImage('assets/Icons/Icona_dashboard.png'),
            width: AppSizes.p28,
            height: AppSizes.p28,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _EmptyBalanceCard extends StatelessWidget {
  const _EmptyBalanceCard();

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Container(
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
                '€0',
                style: AppTextStyles.dashboardBalanceAmount.copyWith(
                  color: AppColors.statusPositive,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: AppSizes.p18),
              Row(
                children: [
                  Expanded(
                    child: _BalanceMetric(
                      label: 'Da ricevere',
                      value: '+€0',
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
                      value: '€0',
                      valueColor: AppColors.statusNegative,
                      align: CrossAxisAlignment.center,
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
  });

  final String title;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CenteredSectionTitle(title),
        const SizedBox(height: AppSizes.p10),
        Container(
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
      ],
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
        Container(
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
                status: 'urgente',
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
      ],
    );
  }
}

class _EmptyTodayTurnSection extends StatelessWidget {
  const _EmptyTodayTurnSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('TURNO DI OGGI'),
        const SizedBox(height: AppSizes.p10),
        Container(
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
          child: const _StatusRow(
            title: 'Nessuna pulizia da fare!',
            status: 'oggi',
            titleColor: AppColors.textOnDark,
          ),
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
  const _EmptyCalendarSection();

  static const List<String> _weekDays = [
    'Lu',
    'Ma',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('CALENDARIO SCADENZE'),
        const SizedBox(height: AppSizes.p10),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.surfaceDark),
            child: Column(
              children: [
                Container(
                  height: AppSizes.p48,
                  color: AppColors.brandSecondary,
                  alignment: Alignment.center,
                  child: const Text(
                    'Aprile',
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
                                  style: AppTextStyles.dashboardCalendarWeekday
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
                      GridView.builder(
                        itemCount: 35,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: AppSizes.p12,
                              crossAxisSpacing: AppSizes.p12,
                              childAspectRatio: 1.3,
                            ),
                        itemBuilder: (context, index) {
                          final day = index < 30 ? '${index + 1}' : '';

                          return Text(
                            day,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.dashboardCalendarDay.copyWith(
                              color: day == '14'
                                  ? AppColors.textMuted
                                  : AppColors.textOnDark,
                              fontSize: 14,
                            ),
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

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav();

  static const List<_NavEntry> _entries = [
    _NavEntry(label: 'Home', asset: 'assets/Icons/home.png', selected: true),
    _NavEntry(label: 'Spese', asset: 'assets/Icons/spese.png'),
    _NavEntry(label: 'Turni', asset: 'assets/Icons/turni.png'),
    _NavEntry(label: 'Scadenze', asset: 'assets/Icons/reminder.png'),
    _NavEntry(label: 'Problemi', asset: 'assets/Icons/problemi.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p8,
        AppSizes.p10,
        AppSizes.p8,
        AppSizes.p8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _entries
            .map((entry) => Expanded(child: _BottomNavItem(entry: entry)))
            .toList(),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.entry});

  final _NavEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.selected ? AppColors.statusInfo : AppColors.textOnDark;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            entry.asset,
            width: AppSizes.p32,
            height: AppSizes.p32,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSizes.p2),
          Text(
            entry.label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: entry.selected
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: color,
              decorationThickness: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavEntry {
  const _NavEntry({
    required this.label,
    required this.asset,
    this.selected = false,
  });

  final String label;
  final String asset;
  final bool selected;
}
