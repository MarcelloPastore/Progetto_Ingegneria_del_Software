import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/state/active_casa_session.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/core/widgets/dashboard/open_problems_section.dart';
import 'package:coincasa_app/features/problemi/screens/problema_dettaglio_screen.dart';
import 'package:coincasa_app/features/problemi/screens/segnala_problema_screen.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProblemiHomeScreen extends ConsumerStatefulWidget {
  const ProblemiHomeScreen({super.key});

  static const String routeName = '/problemi';

  @override
  ConsumerState<ProblemiHomeScreen> createState() => _ProblemiHomeScreenState();
}

class _ProblemiHomeScreenState extends ConsumerState<ProblemiHomeScreen> {
  late Future<List<Problema>> _future;
  int _loadedRevision = -1;

  @override
  void initState() {
    super.initState();
    _loadedRevision = ref.read(problemiRevisionProvider);
    _future = _loadProblemi();
  }

  Future<List<Problema>> _loadProblemi() async {
    final activeCasa = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) return const [];
    final casa = await ensureActiveCasaContext(
      activeCasa,
      caseUtente: caseUtente,
    );
    final list = await ApiProvider.problemi.listNonRisolti(casa.id);
    return list..sort(Problema.compareByPriority);
  }

  @override
  Widget build(BuildContext context) {
    final revision = ref.watch(problemiRevisionProvider);
    if (_loadedRevision != revision) {
      _loadedRevision = revision;
      _future = _loadProblemi();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/problemi'),
        body: FutureBuilder<List<Problema>>(
          future: _future,
          builder: (context, snapshot) {
            final problemi = snapshot.data ?? const <Problema>[];
            final isLoading = snapshot.connectionState != ConnectionState.done;
            final isEmpty = !isLoading && problemi.isEmpty;

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProblemiHomeHeader(isEmpty: isEmpty),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.brandAccent,
                            ),
                          )
                        : snapshot.hasError
                        ? _ErrorBody(
                            onRetry: () =>
                                setState(() => _future = _loadProblemi()),
                          )
                        : isEmpty
                        ? const _EmptyBody()
                        : _ListBody(problemi: problemi),
                  ),
                  _SegnalaButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(SegnalaProblemaScreen.routeName)
                        .then((_) {
                          if (mounted) {
                            setState(() => _future = _loadProblemi());
                          }
                        }),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ProblemiHomeHeader extends StatelessWidget {
  const _ProblemiHomeHeader({required this.isEmpty});

  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final nomeCasa = ActiveCasaScope.read(context).selectedCasa?.nome ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p12, bottom: AppSizes.p12),
      child: Center(
        child: Column(
          children: [
            Text(
              nomeCasa,
              style: const TextStyle(
                color: Color(0xFF8C8CA0),
                fontSize: 20,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Problemi',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.brandAccent,
                fontSize: 40,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji illustration
            const Text('🥱', style: TextStyle(fontSize: 96, height: 1)),
            const SizedBox(height: AppSizes.p32),

            // Title
            Text(
              'Nessun problema aperto',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.textOnDark,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.p12),

            // Subtitle
            Text(
              'La casa è in ottimo stato.\nSegnala un problema se qualcosa non funziona.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColors.textMutedDark,
                fontSize: 15.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Impossibile caricare i problemi',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.textOnDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.p14),
            MainCtaButton(label: 'Riprova', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List state
// ---------------------------------------------------------------------------

class _ListBody extends StatelessWidget {
  const _ListBody({required this.problemi});

  final List<Problema> problemi;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p8,
        AppSizes.p20,
        AppSizes.p16,
      ),
      itemCount: problemi.length,
      separatorBuilder: (context, _) =>
          Divider(height: 1, thickness: 1, color: AppColors.dividerOnDark),
      itemBuilder: (ctx, index) {
        return _ProblemaCard(problema: problemi[index]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Problem card row
// ---------------------------------------------------------------------------

class _ProblemaCard extends StatelessWidget {
  const _ProblemaCard({required this.problema});

  final Problema problema;

  @override
  Widget build(BuildContext context) {
    final assegnatarioNome = _resolveAssegnatario(problema.raw);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).pushNamed(ProblemaDettaglioScreen.routeName, arguments: problema),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _ProblemaAvatar(nome: assegnatarioNome),
              const SizedBox(width: AppSizes.p12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      problema.titolo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.screenTitleStrong.copyWith(
                        color: AppColors.textOnDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p6),

                    // Priority chip
                    _PrioritaChip(priorita: problema.priorita),
                    const SizedBox(height: AppSizes.p5),

                    // Assignee label
                    Text(
                      assegnatarioNome != null
                          ? 'Assegnato a $assegnatarioNome'
                          : 'Nessuno assegnato',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColors.textMutedDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p10),

              // Status badge
              _StatoBadge(stato: problema.stato),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveAssegnatario(Map<String, dynamic> raw) {
    final value =
        raw['assegnatarioNome'] ??
        raw['assegnatario_nome'] ??
        raw['responsabileNome'] ??
        raw['assegnatario'];
    if (value is Map<String, dynamic>) {
      final username = value['username'] ?? value['nome'] ?? value['name'];
      if (username != null && username.toString().trim().isNotEmpty) {
        return username.toString().trim();
      }
    }
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

// ---------------------------------------------------------------------------
// Problem avatar (initials circle)
// ---------------------------------------------------------------------------

class _ProblemaAvatar extends StatelessWidget {
  const _ProblemaAvatar({required this.nome});

  final String? nome;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(nome);
    final hasName = initials != '?';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: hasName
            ? AppColors.brandSecondary.withValues(alpha: 0.28)
            : AppColors.surfaceDarkElevated,
        shape: BoxShape.circle,
        border: Border.all(
          color: hasName ? AppColors.brandAccent : AppColors.dividerOnDark,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: hasName ? AppColors.brandAccent : AppColors.textMutedDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }

  String _initials(String? nome) {
    if (nome == null || nome.trim().isEmpty) return '?';
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Priority chip
// ---------------------------------------------------------------------------

class _PrioritaChip extends StatelessWidget {
  const _PrioritaChip({required this.priorita});

  final String priorita;

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(priorita);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p3,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.foreground,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }

  _ChipConfig _resolveConfig(String priorita) {
    final lower = priorita.toLowerCase();
    if (lower.contains('urgent') || lower == 'urgente') {
      return _ChipConfig(
        label: 'Urgente',
        background: AppColors.problemPriorityUrgent.withValues(alpha: 0.22),
        foreground: AppColors.problemPriorityUrgent,
      );
    }
    if (lower.contains('med') || lower == 'media') {
      return _ChipConfig(
        label: 'Media',
        background: AppColors.problemPriorityMedium.withValues(alpha: 0.22),
        foreground: AppColors.problemPriorityMedium,
      );
    }
    return _ChipConfig(
      label: 'Bassa',
      background: AppColors.problemPriorityLow.withValues(alpha: 0.18),
      foreground: AppColors.problemPriorityLow,
    );
  }
}

class _ChipConfig {
  const _ChipConfig({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatoBadge extends StatelessWidget {
  const _StatoBadge({required this.stato});

  final String stato;

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(stato);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.foreground,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }

  _ChipConfig _resolveConfig(String stato) {
    final lower = stato.toLowerCase();

    if (lower.contains('assegn')) {
      return _ChipConfig(
        label: 'Assegnato',
        background: AppColors.warning.withValues(alpha: 0.22),
        foreground: AppColors.warning,
      );
    }
    if (lower.contains('progress') || lower.contains('corso')) {
      return _ChipConfig(
        label: 'In corso',
        background: AppColors.statusInfo.withValues(alpha: 0.22),
        foreground: AppColors.statusInfo,
      );
    }
    if (lower.contains('risolt') || lower.contains('chiuso')) {
      return _ChipConfig(
        label: 'Risolto',
        background: AppColors.statusSuccess.withValues(alpha: 0.22),
        foreground: AppColors.statusSuccess,
      );
    }
    // default: Segnalato
    return _ChipConfig(
      label: 'Segnalato',
      background: AppColors.statusPositive.withValues(alpha: 0.18),
      foreground: AppColors.statusPositive,
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom CTA button
// ---------------------------------------------------------------------------

class _SegnalaButton extends StatelessWidget {
  const _SegnalaButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p12,
        AppSizes.p20,
        AppSizes.p16,
      ),
      child: MainCtaButton(label: 'Segnala problema', onPressed: onPressed),
    );
  }
}
