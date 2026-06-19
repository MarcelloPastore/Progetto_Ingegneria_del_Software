import 'package:flutter/material.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class PendingDebtsBanner extends StatelessWidget {
  const PendingDebtsBanner({super.key, required this.spese});

  final List<Spesa> spese;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warningSoft.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.warning, width: AppSizes.p1_5),
        borderRadius: BorderRadius.circular(AppSizes.radius10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p14,
              AppSizes.p12,
              AppSizes.p14,
              AppSizes.p8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.keyYellow,
                  size: AppSizes.p20,
                ),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: Text(
                    'Ricordati di pagare le quote pendenti!',
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.keyYellow,
                      fontStyle: FontStyle.italic,
                      fontSize: AppSizes.p14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (spese.isNotEmpty) ...[
            const Divider(
              height: AppSizes.p1,
              thickness: AppSizes.p1,
              color: AppColors.dividerDark,
              indent: AppSizes.p14,
              endIndent: AppSizes.p14,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p14,
                AppSizes.p8,
                AppSizes.p14,
                AppSizes.p12,
              ),
              child: Column(
                children: [
                  for (int i = 0; i < spese.length; i++) ...[
                    _DebtRow(spesa: spese[i]),
                    if (i < spese.length - 1)
                      const Divider(
                        height: AppSizes.p10,
                        thickness: AppSizes.p1,
                        color: AppColors.dividerDark,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.spesa});

  final Spesa spesa;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.receipt_long_rounded,
          color: AppColors.warning,
          size: AppSizes.p14,
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Text(
            spesa.descrizione.isNotEmpty ? spesa.descrizione : 'Spesa',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.warningSoft,
              fontSize: AppSizes.p13,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Text(
          '€${spesa.importo.toStringAsFixed(2)}',
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.keyYellow,
            fontSize: AppSizes.p13,
          ),
        ),
      ],
    );
  }
}
