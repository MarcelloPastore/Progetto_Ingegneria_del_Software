import 'package:flutter/material.dart';
import '../../state/active_casa.dart';
import '../../theme/app_theme.dart';

class AppScreensHeader extends StatelessWidget {
  const AppScreensHeader({
    super.key,
    required this.title,
    this.showHouseName = true,
  });

  final String title;
  final bool showHouseName;

  @override
  Widget build(BuildContext context) {
    final houseName = ActiveCasaScope.read(context).selectedCasa?.nome ?? '';
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          if (showHouseName && houseName.isNotEmpty) ...[
            Text(
              houseName,
              style: AppTextStyles.houseNameHeader.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.p4),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.brandAccent,
              fontSize: AppSizes.p40,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
