import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/problemi/screens/problema_dettaglio_screen.dart';
import 'package:coincasa_app/features/problemi/screens/segnala_problema_screen.dart';

// ---------------------------------------------------------------------------
// Mock data — sostituire con API call quando il backend è pronto
// ---------------------------------------------------------------------------

List<Problema> mockProblemi = [
  Problema(
    id: '1',
    titolo: 'Lavatrice non funziona',
    stato: 'Assegnato',
    priorita: 'Urgente',
    raw: {
      'assegnatarioNome': 'Francesco Paola',
      'descrizione': 'Smette di centrifugare a metà ciclo. Bisogna chiamare il tecnico del costruttore.',
      'segnalatoDa': 'Marco Rossi',
      'segnalatoData': '18 apr',
      'segnalatoOre': '09:15',
      'assegnatoData': '18 apr',
      'assegnatoOre': '11:32',
      'assegnatoNota': 'FP ha accettato',
    },
  ),
  Problema(
    id: '2',
    titolo: 'Caldaia rotta',
    stato: 'Segnalato',
    priorita: 'Media',
    raw: {
      'descrizione': 'Non esce più l\'acqua calda, penso sia la caldaia. Già segnalato al proprietario.',
      'segnalatoDa': 'Luca Bianchi',
      'segnalatoData': '20 apr',
      'segnalatoOre': '08:45',
    },
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProblemiHomeScreen extends StatelessWidget {
  const ProblemiHomeScreen({super.key});

  static const String routeName = '/problemi';

  @override
  Widget build(BuildContext context) {
    final problemi = mockProblemi
        .where((p) => !p.stato.toLowerCase().contains('risolt'))
        .toList();
    final isEmpty = problemi.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/problemi'),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────────
              _ProblemiHomeHeader(isEmpty: isEmpty),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: isEmpty
                    ? const _EmptyBody()
                    : _ListBody(problemi: problemi),
              ),

              // ── Bottom CTA ────────────────────────────────────────────────
              _SegnalaButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(SegnalaProblemaScreen.routeName),
              ),
            ],
          ),
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
    final nomeCasa =
        ActiveCasaScope.read(context).selectedCasa?.nome ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p42, bottom: AppSizes.p12),
      child: Center(
        child: Column(
          children: [
            Text(
              nomeCasa,
              style: const TextStyle(
                color: Color(0xFF8C8CA0),
                fontSize: 14,
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
                        fontSize: 16,
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
                        fontSize: 13,
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
    final nome =
        raw['assegnatarioNome'] ??
        raw['assegnatario_nome'] ??
        raw['assegnatario'] as String?;
    if (nome is String && nome.trim().isNotEmpty) return nome.trim();
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
            fontSize: 16,
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
          fontSize: 12,
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
          fontSize: 12,
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
      child: MainCtaButton(
        label: 'Segnala problema',
        onPressed: onPressed,
      ),
    );
  }
}
