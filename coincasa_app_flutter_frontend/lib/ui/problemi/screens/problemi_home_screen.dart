import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/domain/viewmodel/problemi_viewmodel.dart';
import 'package:coincasa_app/ui/problemi/screens/problema_dettaglio_screen.dart';
import 'package:coincasa_app/ui/problemi/screens/segnala_problema_screen.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProblemiHomeScreen extends ConsumerWidget {
  const ProblemiHomeScreen({super.key});

  static const String routeName = '/problemi';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casaScope = ActiveCasaScope.of(context);
    final casaId = casaScope.selectedCasaId ?? '';
    final vmAsync = ref.watch(problemiViewModelProvider(casaId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/problemi'),
        body: vmAsync.when(
          loading: () => _buildShell(
            context,
            casaId: casaId,
            ref: ref,
            body: const Center(child: CircularProgressIndicator()),
            state: null,
          ),
          error: (e, _) => _buildShell(
            context,
            casaId: casaId,
            ref: ref,
            body: _ErrorBody(
              onRetry: () => ref.invalidate(problemiViewModelProvider(casaId)),
            ),
            state: null,
          ),
          data: (state) => _buildShell(
            context,
            casaId: casaId,
            ref: ref,
            body: state.problemi.isEmpty
                ? _EmptyBody(showTutti: state.mostraTutti)
                : _ListBody(
                    problemi: state.problemi,
                    onBack: () =>
                        ref.invalidate(problemiViewModelProvider(casaId)),
                  ),
            state: state,
          ),
        ),
      ),
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required String casaId,
    required WidgetRef ref,
    required Widget body,
    required ProblemiState? state,
  }) {
    final vm = ref.read(problemiViewModelProvider(casaId).notifier);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProblemiHomeHeader(
            showTutti: state?.mostraTutti ?? false,
            hasRisolti: state?.hasRisolti ?? false,
            onToggleShowTutti: vm.toggleMostraTutti,
          ),
          Expanded(child: body),
          _SegnalaButton(
            onPressed: () => Navigator.of(context)
                .pushNamed(SegnalaProblemaScreen.routeName)
                .then((_) => ref.invalidate(problemiViewModelProvider(casaId))),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ProblemiHomeHeader extends StatelessWidget {
  const _ProblemiHomeHeader({
    required this.showTutti,
    required this.onToggleShowTutti,
    required this.hasRisolti,
  });

  final bool showTutti;
  final VoidCallback onToggleShowTutti;
  final bool hasRisolti;

  @override
  Widget build(BuildContext context) {
    final nomeCasa = ActiveCasaScope.read(context).selectedCasa?.nome ?? '';
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p12, bottom: AppSizes.p12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const AppScreensHeader(title: 'Problemi'),
          if (hasRisolti)
            Positioned(
              right: AppSizes.p16,
              top: 0,
              bottom: 0,
              child: Tooltip(
                message: showTutti ? 'Nascondi risolti' : 'Mostra risolti',
                child: InkWell(
                  onTap: onToggleShowTutti,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p4,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: AppSizes.p28,
                          color: showTutti
                              ? AppColors.brandAccent
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSizes.p2),
                        Text(
                          showTutti ? 'Nascondi risolti' : 'Mostra risolti',
                          style: TextStyle(
                            color: showTutti
                                ? AppColors.brandAccent
                                : cs.onSurfaceVariant,
                            fontSize: AppSizes.p10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.showTutti});

  final bool showTutti;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              showTutti ? '✅' : '🥱',
              style: const TextStyle(fontSize: AppSizes.p80, height: 1),
            ),
            const SizedBox(height: AppSizes.p32),
            Text(
              showTutti
                  ? 'Nessun problema registrato'
                  : 'Nessun problema aperto',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: cs.onSurface,
                fontSize: AppSizes.p23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Text(
              showTutti
                  ? 'Non è ancora stato segnalato nessun problema.'
                  : 'La casa è in ottimo stato.\nSegnala un problema se qualcosa non funziona.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: AppSizes.p15,
                height: AppSizes.p1_5,
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
    final cs = Theme.of(context).colorScheme;
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
                color: cs.onSurface,
                fontSize: AppSizes.p22,
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
  const _ListBody({required this.problemi, required this.onBack});

  final List<Problema> problemi;
  final VoidCallback onBack;

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
      separatorBuilder: (context, _) => Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (ctx, index) {
        return _ProblemaCard(problema: problemi[index], onBack: onBack);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Problem card row
// ---------------------------------------------------------------------------

class _ProblemaCard extends StatelessWidget {
  const _ProblemaCard({required this.problema, required this.onBack});

  final Problema problema;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final assegnatarioNome = _resolveAssegnatario(problema.raw);
    final assegnatarioId =
        (problema.raw['assegnatarioId'] ??
                problema.raw['assegnatario_id'] ??
                problema.raw['responsabileId'])
            ?.toString();

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .pushNamed(ProblemaDettaglioScreen.routeName, arguments: problema)
            .then((_) => onBack()),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                userId: assegnatarioId,
                username: assegnatarioNome,
                radius: AppSizes.p22,
                fallback: '?',
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problema.titolo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.screenTitleStrong.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: AppSizes.p18,
                        fontWeight: FontWeight.w700,
                        height: AppSizes.p1_25,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p6),
                    _PrioritaChip(priorita: problema.priorita),
                    const SizedBox(height: AppSizes.p5),
                    Text(
                      assegnatarioNome != null
                          ? 'Assegnato a $assegnatarioNome'
                          : 'Nessuno assegnato',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: AppSizes.p14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p10),
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
          fontSize: AppSizes.p15,
          fontWeight: FontWeight.w800,
          height: AppSizes.p1_2,
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
          fontSize: AppSizes.p15,
          fontWeight: FontWeight.w700,
          height: AppSizes.p1_2,
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
