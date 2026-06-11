import 'package:flutter/material.dart';

import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/problemi/screens/problema_dettaglio_dashboard_screen.dart';

final _mockProblemi = [
  Problema(
    id: 'dash-1',
    titolo: 'Lavatrice non funziona',
    stato: 'Assegnato',
    priorita: 'Urgente',
    raw: {
      'segnalatoDa': 'Francesco P.',
      'segnalatoData': '18 apr',
      'assegnatarioNome': 'Francesco P.',
      'descrizione': 'La lavatrice si blocca a metà ciclo e fa un rumore strano alla centrifuga.',
    },
  ),
  Problema(
    id: 'dash-2',
    titolo: 'Perdita rubinetto bagno',
    stato: 'Segnalato',
    priorita: 'Media',
    raw: {
      'segnalatoDa': 'Anna L.',
      'segnalatoData': '20 apr',
      'descrizione': 'Il rubinetto del bagno perde lentamente, bisogna stringere il raccordo.',
    },
  ),
  Problema(
    id: 'dash-3',
    titolo: 'Plafoniera corridoio fulminata',
    stato: 'Segnalato',
    priorita: 'Bassa',
    raw: {
      'segnalatoDa': 'Marco C.',
      'segnalatoData': '21 apr',
      'descrizione': 'La luce del corridoio non si accende, probabilmente la plafoniera è fulminata.',
    },
  ),
];

const _initials = ['FP', 'AL', 'MC'];

class OpenProblemsSection extends StatelessWidget {
  const OpenProblemsSection({super.key});

  @override
  Widget build(BuildContext context) {
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
              BoxShadow(color: AppColors.shadowSoft, blurRadius: AppSizes.p20, offset: Offset(0, AppSizes.p8)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p18, vertical: AppSizes.p16),
          child: Column(
            children: [
              for (var i = 0; i < _mockProblemi.length; i++) ...[
                _ProblemRow(problema: _mockProblemi[i], initials: _initials[i]),
                if (i < _mockProblemi.length - 1)
                  Divider(height: 1, thickness: 1, color: AppColors.dividerOnDark),
              ],
              const SizedBox(height: AppSizes.p14),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/problemi'),
                child: Center(
                  child: Text('Vedi tutti', style: AppTextStyles.dashboardSectionLink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProblemRow extends StatelessWidget {
  const _ProblemRow({required this.problema, required this.initials});

  final Problema problema;
  final String initials;

  Color get _priorityColor {
    switch (problema.priorita.toLowerCase()) {
      case 'urgente': return AppColors.statusNegative;
      case 'media':   return AppColors.statusWarning;
      default:        return AppColors.statusSuccess;
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
              initials,
              style: AppTextStyles.dashboardProblemInitials.copyWith(color: _priorityColor),
            ),
          ),
          const SizedBox(width: AppSizes.p14),
          Expanded(
            child: Text(
              problema.titolo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.dashboardCardTitleOnDark.copyWith(color: _priorityColor),
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
