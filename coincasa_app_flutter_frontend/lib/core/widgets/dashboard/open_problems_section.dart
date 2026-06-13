import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/problemi/screens/problema_dettaglio_dashboard_screen.dart';

final problemiRevisionProvider = StateProvider<int>((ref) => 0);

final openProblemsProvider = FutureProvider.autoDispose
    .family<List<Problema>, String?>((ref, casaId) {
      ref.watch(problemiRevisionProvider);
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
    final problemiAsync = ref.watch(openProblemsProvider(casaId));

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
              final sortedProblemi = List<Problema>.from(problemi)
                ..sort(Problema.compareByPriority);

              final visible = sortedProblemi.take(3).toList(growable: false);
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p10,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
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

  Color get _priorityColor {
    switch (problema.priorita.toLowerCase()) {
      case 'urgente':
        return AppColors.problemPriorityUrgent;
      case 'media':
        return AppColors.problemPriorityMedium;
      default:
        return AppColors.problemPriorityLow;
    }
  }

  IconData get _priorityIcon {
    switch (problema.priorita.toLowerCase()) {
      case 'urgente':
        return Icons.priority_high_rounded;
      case 'media':
        return Icons.remove_rounded;
      default:
        return Icons.arrow_downward_rounded;
    }
  }

  String? get _segnalatoData {
    final raw = problema.raw['segnalatoData']?.toString();
    if (raw != null && raw.isNotEmpty) return raw;
    final iso = problema.raw['dataCreazione']?.toString();
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final segnalato = _segnalatoData;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.p22 * 2,
            height: AppSizes.p22 * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _priorityColor.withValues(alpha: 0.18),
              border: Border.all(color: _priorityColor, width: 1.5),
            ),
            child: Icon(
              _priorityIcon,
              color: _priorityColor,
              size: AppSizes.p22,
            ),
          ),
          const SizedBox(width: AppSizes.p14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  problema.titolo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.dashboardCardTitleOnDark.copyWith(
                    color: _priorityColor,
                  ),
                ),
                if (segnalato != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'segnalato il $segnalato',
                    style: TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
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
