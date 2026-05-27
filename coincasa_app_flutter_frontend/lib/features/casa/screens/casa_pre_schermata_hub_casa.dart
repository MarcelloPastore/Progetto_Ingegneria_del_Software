import 'package:flutter/material.dart';
import 'package:coincasa_app/features/casa/screens/hub_casa_admin.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class CasaPreSchermataHubCasaScreen extends StatelessWidget {
  final String houseName;

  const CasaPreSchermataHubCasaScreen({super.key, required this.houseName});

  @override
  Widget build(BuildContext context) {
    final normalizedHouseName = houseName.trim();
    final displayHouseName = normalizedHouseName.isEmpty
        ? 'Casa'
        : normalizedHouseName.toLowerCase().startsWith('casa ')
        ? normalizedHouseName
        : 'Casa $normalizedHouseName';
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p24,
                  vertical: AppSizes.p24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _WelcomeContent(displayHouseName: displayHouseName),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  final String displayHouseName;

  const _WelcomeContent({required this.displayHouseName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSizes.p68,
          height: AppSizes.p68,
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(AppSizes.radius14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radius14),
            child: Image.asset(
              'assets/Icons/home_auth_icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        Text(
          'Benvenuto in\n$displayHouseName!',
          textAlign: TextAlign.center,
          style: AppTextStyles.strongTitle.copyWith(fontSize: 20, height: 1.15),
        ),
        const SizedBox(height: AppSizes.p18),
        Text(
          'Ti sei unito alla casa con\nsuccesso. Ora puoi\ngestire tutto insieme ai\ntuoi coinquilini.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.p32),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => const HubCasaAdminScreen(),
              ),
              (route) => false,
            );
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.p56),
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: AppColors.textOnDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              side: const BorderSide(color: AppColors.primaryBorder, width: 1),
            ),
          ),
          child: Text(
            'Vai all\'Hub Casa',
            style: AppTextStyles.buttonCompact.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
