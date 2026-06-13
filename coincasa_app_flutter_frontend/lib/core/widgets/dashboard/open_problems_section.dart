import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/problemi/screens/problema_dettaglio_dashboard_screen.dart';

final _openProblemsProvider = FutureProvider.autoDispose
    .family<List<Problema>, String?>((ref, casaId) {
      if (casaId == null || casaId.isEmpty) return const [];
      return ApiProvider.problemi.listNonRisolti(casaId);
    });

class OpenProblemsSection extends ConsumerWidget {
  const OpenProblemsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casaId = ref.watch(
      activeCasaProvider.select((state) => state.selectedCasaId),
    );
    final problemiAsync = ref.watch(_openProblemsProvider(casaId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'PROBLEMI APERTI',
            style: AppTextStyles.dashboardSectionTitle.copyWith(
              color: AppColors.textMuted,
              fontSize: 18,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkElevated,
            borderRadius: BorderRadius.circular(AppSizes.radius24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: AppSizes.p20,
                offset: Offset(0, AppSizes.p8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p18,
            vertical: AppSizes.p16,
          ),
          child: problemiAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSizes.p16),
              child: CircularProgressIndicator(color: AppColors.brandAccent),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(AppSizes.p12),
              child: Text(
                'Problemi non disponibili',
                style: TextStyle(color: AppColors.textMutedDark),
              ),
            ),
            data: (problemi) {
              final visible = problemi.take(3).toList(growable: false);
              return Column(
                children: [
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSizes.p12),
                      child: Text(
                        'Nessun problema aperto',
                        style: TextStyle(color: AppColors.textMutedDark),
                      ),
                    ),
                  for (var i = 0; i < visible.length; i++) ...[
                    _ProblemRow(problema: visible[i]),
                    if (i < visible.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.dividerOnDark,
                      ),
                  ],
                  const SizedBox(height: AppSizes.p14),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/problemi'),
                    child: Center(
                      child: Text(
                        'Vedi tutti',
                        style: AppTextStyles.dashboardSectionLink,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProblemRow extends StatelessWidget {
  const _ProblemRow({required this.problema});

  final Problema problema;

  String get _initials {
    final source =
        (problema.raw['assegnatarioNome'] ??
                problema.raw['segnalatoDa'] ??
                problema.titolo)
            .toString()
            .trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    return parts.length > 1
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();
  }

  Color get _priorityColor {
    switch (problema.priorita.toLowerCase()) {
      case 'urgente':
        return AppColors.statusNegative;
      case 'media':
        return AppColors.statusWarning;
      default:
        return AppColors.statusSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizes.p22,
            backgroundColor: _priorityColor.withValues(alpha: 0.18),
            child: Text(
              _initials,
              style: AppTextStyles.dashboardProblemInitials.copyWith(
                color: _priorityColor,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.p14),
          Expanded(
            child: Text(
              problema.titolo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.dashboardCardTitleOnDark.copyWith(
                color: _priorityColor,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          GestureDetector(
            onTap: () => showProblemaDettaglio(context, problema),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.brandAccent.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                'Vedi',
                style: TextStyle(
                  color: AppColors.brandAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
