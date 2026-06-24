import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:coincasa_app/app.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/data/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/dashboard/house_health_section.dart';
import 'package:coincasa_app/core/widgets/dashboard/open_problems_section.dart';
import 'package:coincasa_app/data/models/dashboard_data.dart';
import 'package:coincasa_app/domain/viewmodel/dashboard_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/scadenze_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/turni_viewmodel.dart';
import 'package:coincasa_app/ui/casa/screens/casa_welcome_screen.dart';
import 'package:coincasa_app/ui/dashboard_crea_popup.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with RouteAware {
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

  @override
  void didPopNext() {
    super.didPopNext();
    ref.read(dashboardViewModelProvider.notifier).refresh();
  }

  void _navigateToWelcome() {
    final client = ApiProvider.client;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CasaWelcomeScreen(
          email: client.currentUserEmail ?? '',
          userId: client.currentUserId,
          username: client.currentUserUsername,
          displayName: client.currentUserDisplayName,
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _completaTurno(String casaId, String turnoId) async {
    try {
      await ref
          .read(dashboardViewModelProvider.notifier)
          .completaTurno(casaId, turnoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turno completato con successo!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile completare il turno. Riprova.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<DashboardState>>(dashboardViewModelProvider, (
      _,
      next,
    ) {
      if (next case AsyncError(:final error) when error is StateError) {
        _navigateToWelcome();
      }
    });

    final vmAsync = ref.watch(dashboardViewModelProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
        body: SafeArea(
          child: vmAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brandAccent),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (state) => Stack(
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
                        data: state.data,
                        onCasaChanged: (id) {
                          ref
                              .read(dashboardViewModelProvider.notifier)
                              .selectCasa(id)
                              .catchError((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Impossibile cambiare casa. Riprova.',
                                      ),
                                    ),
                                  );
                                }
                              });
                        },
                      ),
                      const SizedBox(height: AppSizes.p12),
                      _EmptyBalanceCard(
                        casaId: state.data.casaSelezionataId,
                        data: state.data,
                      ),
                      const SizedBox(height: AppSizes.p28),
                      _ReactiveHouseHealthSection(
                        casaId: state.data.casaSelezionataId,
                        fallbackBadges: state.houseHealthBadges
                            .map(
                              (t) => HouseHealthBadgeData(
                                caption: t.titolo,
                                giorniRimanenti: t.giorniRimanenti,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: AppSizes.p28),
                      _ProssimeScadenzeSection(
                        casaId: state.data.casaSelezionataId,
                        spese: state.data.spese,
                      ),
                      const SizedBox(height: AppSizes.p28),
                      const OpenProblemsSection(),
                      const SizedBox(height: AppSizes.p28),
                      _TodayTurnSection(
                        casaId: state.data.casaSelezionataId,
                        fallbackTurniOggi: state.data.turniOggi,
                        completingTurnoIds: state.completingTurnoIds,
                        onCompletaTurno: (turnoId) => _completaTurno(
                          state.data.casaSelezionataId ?? '',
                          turnoId,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p28),
                      _EmptyCalendarSection(data: state.data),
                    ],
                  ),
                ),
                if (state.isBackgroundRefreshing)
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
      ),
    );
  }
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar({this.radius = AppSizes.p23});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ActiveCasaScope.of(context).isHomeAdmin;
    final client = ApiProvider.client;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(
          radius: radius,
          userId: client.currentUserAvatarSeed,
          username: client.currentUserUsername,
        ),
        if (isAdmin) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.keyYellow,
                  AppColors.lockOrange,
                  AppColors.keyYellow,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.keyYellow.withValues(alpha: 0.53),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Admin',
              style: TextStyle(
                color: AppColors.lockHole,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Color(0x44FFFFFF),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyDashboardHeader extends StatelessWidget {
  const _EmptyDashboardHeader({
    required this.data,
    required this.onCasaChanged,
  });

  final DashboardData data;
  final ValueChanged<String> onCasaChanged;

  static String _formatNomeCasa(Casa casa) {
    final nome = casa.nome.trim();
    if (nome.isEmpty) return 'Casa senza nome';
    return nome.toLowerCase().startsWith('casa ') ? nome : 'Casa $nome';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/account'),
          customBorder: const CircleBorder(),
          child: const _CurrentUserAvatar(radius: AppSizes.p23),
        ),
        const SizedBox(width: AppSizes.p14),
        Expanded(
          child: data.caseUtente.length > 1
              ? _HouseSelector(
                  caseUtente: data.caseUtente,
                  selectedCasaId: data.casaSelezionataId,
                  formatNomeCasa: _formatNomeCasa,
                  onCasaChanged: onCasaChanged,
                )
              : Text(
                  data.nomeCasa,
                  style: AppTextStyles.dashboardHeaderTitle.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(color: colorScheme.outline),
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
            icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.primary),
            dropdownColor: colorScheme.surface,
            style: AppTextStyles.dashboardHeaderTitle.copyWith(
              color: colorScheme.onSurface,
            ),
            selectedItemBuilder: (context) {
              return caseUtente.map((casa) {
                return Center(
                  child: Text(
                    formatNomeCasa(casa),
                    style: AppTextStyles.dashboardHeaderTitle.copyWith(
                      color: colorScheme.onSurface,
                    ),
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

class _EmptyBalanceCard extends ConsumerWidget {
  const _EmptyBalanceCard({required this.casaId, required this.data});

  final String? casaId;
  final DashboardData data;

  String _formatAmount(double? value, {bool showPlus = false}) {
    if (value == null) return '€0';
    final rounded = value.toStringAsFixed(2);
    final normalized = rounded.endsWith('.00')
        ? rounded.substring(0, rounded.length - 3)
        : rounded;
    final prefix = value < 0
        ? '-'
        : showPlus && value > 0
        ? '+'
        : '';
    return '$prefix€${normalized.replaceFirst('-', '')}';
  }

  Color _saldoColor(double? saldo) {
    if (saldo == null || saldo >= 0) return AppColors.statusPositive;
    return AppColors.statusNegative;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double? saldo = data.saldo;
    double? credito = data.credito;
    double? debito = data.debito;

    if (casaId != null && casaId!.isNotEmpty) {
      final speseAsync = ref.watch(speseViewModelProvider(casaId!));
      if (speseAsync.hasValue) {
        saldo = speseAsync.requireValue.saldo;
        credito = speseAsync.requireValue.creditoTotale;
        debito = speseAsync.requireValue.debitoTotale;
      }
    }

    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/spese'),
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Column(
        children: [
          Text(
            'IL TUO SALDO',
            style: AppTextStyles.dashboardHeaderSubtitle.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                          color: AppColors.textOnDark,
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
                        value: _formatAmount(credito, showPlus: true),
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
                        value: _formatAmount(debito),
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

class _ProssimeScadenzeSection extends ConsumerWidget {
  const _ProssimeScadenzeSection({required this.casaId, required this.spese});

  final String? casaId;
  final List<Spesa> spese;

  List<ProssimeScadenzeEntry> _compute(List<Scadenza> scadenze) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entries = <ProssimeScadenzeEntry>[];

    final idScadenzeConSpesa = spese
        .map((s) => s.idScadenza)
        .whereType<String>()
        .toSet();

    for (final spesa in spese) {
      final d = spesa.dataScadenza;
      if (d == null) continue;
      if (d.year == now.year && d.month == now.month) {
        entries.add(
          ProssimeScadenzeEntry(
            nome: spesa.descrizione,
            date: DateTime(d.year, d.month, d.day),
          ),
        );
      }
    }

    for (final sc in scadenze) {
      if (idScadenzeConSpesa.contains(sc.id)) continue;
      final d = sc.dataScadenza;
      if (d.year == now.year && d.month == now.month) {
        entries.add(
          ProssimeScadenzeEntry(
            nome: sc.nome,
            date: DateTime(d.year, d.month, d.day),
          ),
        );
      }
    }

    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries.where((e) => !e.date.isBefore(today)).take(3).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = casaId;
    List<ProssimeScadenzeEntry> entries = const [];
    if (id != null && id.isNotEmpty) {
      final scadenzeAsync = ref.watch(scadenzeViewModelProvider(id));
      if (scadenzeAsync.hasValue) {
        entries = _compute(scadenzeAsync.requireValue.scadenze);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('PROSSIME SCADENZE'),
        const SizedBox(height: AppSizes.p10),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/scadenze'),
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
              AppSizes.p14,
              AppSizes.p16,
            ),
            child: entries.isEmpty
                ? SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'Nessuna scadenza questo mese',
                        style: AppTextStyles.dashboardCardSubtitleOnDark
                            .copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: entries
                        .asMap()
                        .entries
                        .map(
                          (e) => Padding(
                            padding: EdgeInsets.only(
                              bottom: e.key < entries.length - 1
                                  ? AppSizes.p12
                                  : 0,
                            ),
                            child: _ScadenzaRow(entry: e.value),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ScadenzaRow extends StatelessWidget {
  const _ScadenzaRow({required this.entry});

  final ProssimeScadenzeEntry entry;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = entry.date.difference(today).inDays;

    final Color dotColor;
    final String label;
    if (days == 0) {
      dotColor = AppColors.statusPositive;
      label = 'oggi';
    } else if (days <= 3) {
      dotColor = AppColors.statusNegative;
      label = '$days ${days == 1 ? 'giorno' : 'giorni'}';
    } else if (days <= 10) {
      dotColor = AppColors.lockOrange;
      label = '$days giorni';
    } else {
      dotColor = AppColors.statusPositive;
      label = '$days giorni';
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.p10),
        Expanded(
          child: Text(
            entry.nome,
            style: AppTextStyles.dashboardCardTitleOnDark.copyWith(
              color: AppColors.textOnDark,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Text(
          label,
          style: AppTextStyles.dashboardListStatus.copyWith(
            color: dotColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TodayTurnSection extends ConsumerWidget {
  const _TodayTurnSection({
    required this.casaId,
    required this.fallbackTurniOggi,
    required this.completingTurnoIds,
    required this.onCompletaTurno,
  });

  final String? casaId;
  final List<Turno> fallbackTurniOggi;
  final Set<String> completingTurnoIds;
  final void Function(String turnoId) onCompletaTurno;

  Widget _buildCompleteButton(Turno turno) {
    if (completingTurnoIds.contains(turno.id)) {
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
          gradient: AppGradients.whiteOverlay(topAlpha: 0.20),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: AppColors.lockOrange,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadowOverlay,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: OutlinedButton(
          onPressed: () => onCompletaTurno(turno.id),
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

  Widget _buildTurnoRow(Turno turno, bool isLast) {
    final currentUserId = ApiProvider.client.currentUserId;
    final isCurrentAssignee = turno.assegnatarioId == currentUserId;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.p12),
      child: Row(
        children: [
          UserAvatar(
            radius: 24,
            userId: turno.assegnatarioId,
            username: turno.assegnatarioNome.isNotEmpty
                ? turno.assegnatarioNome
                : null,
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
          if (casaId != null && isCurrentAssignee) ...[
            const SizedBox(width: AppSizes.p8),
            _buildCompleteButton(turno),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Turno> turniOggi = fallbackTurniOggi;
    if (casaId != null && casaId!.isNotEmpty) {
      final turniAsync = ref.watch(turniViewModelProvider(casaId!));
      if (turniAsync.hasValue) {
        turniOggi = turniAsync.requireValue.turniOggi;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('TURNI DI OGGI'),
        const SizedBox(height: AppSizes.p10),
        InkWell(
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
            child: turniOggi.isEmpty
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
                    children: List.generate(
                      turniOggi.length,
                      (i) => _buildTurnoRow(
                        turniOggi[i],
                        i == turniOggi.length - 1,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wrapper reattivo per HouseHealthSection — legge turni e salute dal
// turniViewModelProvider in modo da aggiornarsi senza ricaricare tutta
// la dashboard.
// ---------------------------------------------------------------------------

class _ReactiveHouseHealthSection extends ConsumerWidget {
  const _ReactiveHouseHealthSection({
    required this.casaId,
    required this.fallbackBadges,
  });

  final String? casaId;
  final List<HouseHealthBadgeData> fallbackBadges;

  static int _colorGroup(int? giorni) {
    if (giorni == null || giorni < -3) return 0;
    if (giorni <= 0) return 1;
    if (giorni <= 2) return 2;
    return 3;
  }

  static int _compareBadges(HouseHealthBadgeData a, HouseHealthBadgeData b) {
    final ga = _colorGroup(a.giorniRimanenti);
    final gb = _colorGroup(b.giorniRimanenti);
    if (ga != gb) return ga.compareTo(gb);
    final da = a.giorniRimanenti;
    final db = b.giorniRimanenti;
    if (da == null && db == null) return 0;
    if (da == null) return -1;
    if (db == null) return 1;
    if (ga <= 1) return db.abs().compareTo(da.abs());
    return da.compareTo(db);
  }

  static List<HouseHealthBadgeData> _computeBadges(TurniState turniState) {
    final saluteMap = {for (final s in turniState.saluteCasa) s.id: s};
    final badges = turniState.turni
        .map((turno) {
          final titolo = turno.titolo.trim();
          if (titolo.isEmpty) return null;
          return HouseHealthBadgeData(
            caption: titolo,
            giorniRimanenti: saluteMap[turno.id]?.giorniRimanenti,
          );
        })
        .whereType<HouseHealthBadgeData>()
        .toList();
    badges.sort(_compareBadges);
    return badges;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var badges = fallbackBadges;
    if (casaId != null && casaId!.isNotEmpty) {
      final turniAsync = ref.watch(turniViewModelProvider(casaId!));
      if (turniAsync.hasValue) {
        badges = _computeBadges(turniAsync.requireValue);
      }
    }
    return HouseHealthSection(badges: badges);
  }
}

class _EmptyCalendarSection extends ConsumerWidget {
  const _EmptyCalendarSection({required this.data});

  final DashboardData data;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final days = _buildGridDays(month);

    final casaId = data.casaSelezionataId;
    List<Scadenza> scadenze = data.scadenze;
    List<Spesa> spese = data.spese;
    List<Turno> turni = data.turni;
    if (casaId != null && casaId.isNotEmpty) {
      final scadenzeAsync = ref.watch(scadenzeViewModelProvider(casaId));
      if (scadenzeAsync.hasValue) {
        scadenze = scadenzeAsync.requireValue.scadenze;
      }
      final speseAsync = ref.watch(speseViewModelProvider(casaId));
      if (speseAsync.hasValue) {
        spese = speseAsync.requireValue.spese;
      }
      final turniAsync = ref.watch(turniViewModelProvider(casaId));
      if (turniAsync.hasValue) {
        turni = turniAsync.requireValue.turni;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('CALENDARIO SCADENZE'),
        const SizedBox(height: AppSizes.p10),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/scadenze'),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: Container(
            clipBehavior: Clip.antiAlias,
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
              child: Column(
                children: [
                  Container(
                    height: AppSizes.p48,
                    color: AppColors.brandSecondary,
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[month.month - 1],
                      style: const TextStyle(
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
                        GridView.builder(
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
                                ? _markersForDate(
                                    date,
                                    turni,
                                    spese,
                                    scadenze,
                                  )
                                : const <Color>[];
                            return _DashboardCalendarDay(
                              day: inMonth ? '${date.day}' : '',
                              markers: markers,
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
    List<Scadenza> scadenze,
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
    final idScadenzeConSpesa = spese
        .map((s) => s.idScadenza)
        .whereType<String>()
        .toSet();
    for (final sc in scadenze) {
      if (idScadenzeConSpesa.contains(sc.id)) continue;
      final d = sc.dataScadenza;
      if (d.year == date.year && d.month == date.month && d.day == date.day) {
        if (!colors.contains(AppColors.statusNegative)) {
          colors.add(AppColors.statusNegative);
        }
        break;
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
    if (day.isEmpty) return const SizedBox.shrink();

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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
