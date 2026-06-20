import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/formatters.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/spese/screens/dettaglio_spesa_debitore.dart';
import 'package:coincasa_app/features/spese/screens/inserisci_spesa_membro.dart';
import 'package:coincasa_app/features/spese/screens/pareggia_conti.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';

class ListaSpeseMembroScreen extends ConsumerStatefulWidget {
  const ListaSpeseMembroScreen({super.key});

  static const String routeName = '/spese/membro';

  @override
  ConsumerState<ListaSpeseMembroScreen> createState() =>
      _ListaSpeseMembroScreenState();
}

class _ListaSpeseMembroScreenState extends ConsumerState<ListaSpeseMembroScreen>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    // Invalida il provider ad ogni apertura della schermata (anche via pushReplacementNamed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final casaId = ActiveCasaScope.read(context).selectedCasaId;
      if (casaId != null) {
        ref.invalidate(speseViewModelProvider(casaId));
      }
      ref.invalidate(memberSpeseDataProvider(casaId));
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
    ref.invalidate(memberSpeseDataProvider(selectedCasaId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCasaId = ActiveCasaScope.read(context).selectedCasaId;
    final asyncData = ref.watch(memberSpeseDataProvider(selectedCasaId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
        body: SafeArea(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const _StateMessage(message: 'Dati non disponibili.'),
            data: (data) => data == null
                ? const _StateMessage(message: 'Nessuna casa disponibile.')
                : _MemberSpeseContent(data: data),
          ),
        ),
      ),
    );
  }
}

class _MemberSpeseContent extends StatelessWidget {
  const _MemberSpeseContent({required this.data});

  final MemberSpeseData data;

  @override
  Widget build(BuildContext context) {
    final groups = data.groupedSpese;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p14,
              AppSizes.p8,
              AppSizes.p14,
              AppSizes.p16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.featureAccent,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: AppSizes.p28,
                      height: AppSizes.p28,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Spese',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      color: AppColors.brandAccent,
                      fontSize: AppSizes.p40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.p20),
                _SummaryCard(data: data),
                const SizedBox(height: AppSizes.p25),
                for (final entry in groups.entries) ...[
                  _MonthTitle(entry.key),
                  const SizedBox(height: AppSizes.p8),
                  for (int index = 0; index < entry.value.length; index++) ...[
                    _ExpenseTile(spesa: entry.value[index]),
                    if (index < entry.value.length - 1)
                      const Divider(
                        height: AppSizes.p1,
                        color: AppColors.borderSubtle,
                      ),
                  ],
                  const SizedBox(height: AppSizes.p28),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16,
            AppSizes.p8,
            AppSizes.p16,
            AppSizes.p14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.spese.isNotEmpty) ...[
                SecondaryCtaButton(
                  label: 'Pareggia i conti',
                  color: MainCtaColors.turni,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(PareggiaContiScreen.routeName),
                ),
                const SizedBox(height: AppSizes.p10),
              ],
              MainCtaButton(
                label: 'Inserisci nuova spesa',
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(InserisciSpesaMembroScreen.routeName),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final MemberSpeseData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p13,
        AppSizes.p12,
        AppSizes.p13,
        AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkMuted,
        border: Border.all(color: AppColors.borderSubtle, width: AppSizes.p1_2),
        borderRadius: BorderRadius.circular(AppSizes.radius8),
      ),
      child: Column(
        children: [
          Text(
            'SALDO MESE - ${monthName(DateTime.now().month).toUpperCase()} ${DateTime.now().year}',
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: AppSizes.p16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: AppSizes.p22),
          Row(
            children: [
              _SummaryColumn(
                label: 'Totale mese',
                value: formatCurrency(data.totaleMese),
                color: AppColors.textOnDark,
              ),
              const _VerticalLine(),
              _SummaryColumn(
                label: 'Devi ricevere',
                value: formatCurrency(data.credito),
                color: AppColors.statusPositive,
              ),
              const _VerticalLine(),
              _SummaryColumn(
                label: 'Devi pagare',
                value: formatCurrency(data.debito),
                color: AppColors.statusNegative,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: AppSizes.p13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppSizes.p21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.spesa});

  final Spesa spesa;

  @override
  Widget build(BuildContext context) {
    final creator = spesa.creatoreNome.isEmpty
        ? 'coinquilino'
        : spesa.creatoreNome;
    final isPagata = spesaStatusFor(spesa, null) == SpesaStatus.pagata;

    return Opacity(
      opacity: isPagata ? 0.4 : 1.0,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          DettaglioSpesaDebitoreScreen.routeName,
          arguments: spesa.id,
        ),
        child: Container(
          height: AppSizes.p39,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p5),
          color: AppColors.transparent,
          child: Row(
            children: [
              UserAvatar(displayName: creator, radius: 18),
              const SizedBox(width: AppSizes.p13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TitleWithDate(
                      title: spesa.descrizione.isEmpty
                          ? 'Spesa'
                          : spesa.descrizione,
                      date: '${spesa.data.day} ${monthShort(spesa.data.month)}',
                    ),
                    Text(
                      isPagata ? 'Pagata' : '$creator ha pagato',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPagata
                            ? AppColors.statusPositive
                            : AppColors.textDim,
                        fontSize: AppSizes.p11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatCurrency(spesa.importo),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: AppSizes.p15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthTitle extends StatelessWidget {
  const _MonthTitle(this.month);

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final closed = month.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month),
    );
    final color = closed
        ? AppColors.textMutedDark
        : Theme.of(context).colorScheme.onSurface;

    return Text(
      '${monthName(month.month).toUpperCase()} ${month.year}${closed ? ' (chiuso)' : ''}',
      style: TextStyle(
        color: color,
        fontSize: AppSizes.p17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _VerticalLine extends StatelessWidget {
  const _VerticalLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.p1,
      height: AppSizes.p35,
      color: AppColors.borderSubtle,
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _TitleWithDate extends StatelessWidget {
  const _TitleWithDate({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: AppSizes.p15,
      fontWeight: FontWeight.w800,
    );
    final dateStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: AppSizes.p11,
      fontWeight: FontWeight.w400,
    );

    if (date.isEmpty) {
      return Text(
        title,
        style: titleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final titlePainter = TextPainter(
          text: TextSpan(text: title, style: titleStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: double.infinity);

        final datePainter = TextPainter(
          text: TextSpan(text: '  $date', style: dateStyle),
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
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showDate) ...[
              const SizedBox(width: AppSizes.p6),
              Text(date, style: dateStyle),
            ],
          ],
        );
      },
    );
  }
}
