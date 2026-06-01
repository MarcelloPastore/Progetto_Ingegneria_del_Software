import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: AppSizes.p22,
          backgroundColor: AppColors.surfaceTint,
          child: Text(
            resolveUserInitials(
              displayName: ApiProvider.client.currentUserName,
              email: ApiProvider.client.currentUserEmail,
              fallback: '??',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text('Casa Verdi', style: AppTextStyles.dashboardHeaderTitle),
              SizedBox(height: AppSizes.p4),
              Text(
                'IL TUO SALDO',
                style: AppTextStyles.dashboardHeaderSubtitle,
              ),
            ],
          ),
        ),
        const CircleAvatar(
          radius: AppSizes.p20,
          backgroundColor: AppColors.surfaceTint,
          child: Image(
            image: AssetImage('assets/Icons/Icona_dashboard.png'),
            width: AppSizes.p22,
            height: AppSizes.p22,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
