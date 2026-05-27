import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/casa/screens/hub_casa_admin.dart';

class CasaPreSchermataHubCasaScreen extends StatelessWidget {
  const CasaPreSchermataHubCasaScreen({
    super.key,
    required this.houseName,
    this.houseType = '',
    this.city = '',
    this.roommatesCount = 3,
  });

  final String houseName;
  final String houseType;
  final String city;
  final int roommatesCount;

  @override
  Widget build(BuildContext context) {
    final displayHouseName = _formatHouseName(houseName);
    final locationText = _formatLocationText(houseType: houseType, city: city);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p30,
                    vertical: AppSizes.p24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.05),
                      Image.asset(
                        'assets/Icons/green_check_mark.png',
                        width: AppSizes.p100,
                        height: AppSizes.p100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSizes.p22),
                      const Text(
                        'Codice valido!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p30),
                      _HousePreviewCard(
                        houseName: displayHouseName,
                        locationText: locationText,
                        roommatesCount: roommatesCount,
                      ),
                      const SizedBox(height: AppSizes.p32),
                      _PrimaryEnterButton(houseName: displayHouseName),
                      const SizedBox(height: AppSizes.p18),
                      const _CancelButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatHouseName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Casa';
    }
    if (normalized.toLowerCase().startsWith('casa ')) {
      return normalized;
    }
    return 'Casa $normalized';
  }

  String _formatLocationText({
    required String houseType,
    required String city,
  }) {
    final normalizedType = houseType.trim();
    final normalizedCity = city.trim();

    if (normalizedType.isNotEmpty && normalizedCity.isNotEmpty) {
      return '$normalizedType - $normalizedCity';
    }
    if (normalizedType.isNotEmpty) {
      return normalizedType;
    }
    if (normalizedCity.isNotEmpty) {
      return normalizedCity;
    }
    return 'Casa condivisa';
  }
}

class _HousePreviewCard extends StatelessWidget {
  const _HousePreviewCard({
    required this.houseName,
    required this.locationText,
    required this.roommatesCount,
  });

  final String houseName;
  final String locationText;
  final int roommatesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p20,
        AppSizes.p18,
        AppSizes.p20,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFillDark,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        border: Border.all(color: AppColors.inputBorderDark, width: 2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Icons/home.png',
                width: AppSizes.p90,
                height: AppSizes.p90,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: AppSizes.p18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      houseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text(
                      locationText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 18,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p18),
          Row(
            children: [
              const _RoommateAvatar(label: 'FP', color: Color(0xFF356F9F)),
              const SizedBox(width: AppSizes.p14),
              const _RoommateAvatar(label: 'AL', color: Color(0xFFFFB17D)),
              const SizedBox(width: AppSizes.p14),
              const _RoommateAvatar(label: 'GL', color: Color(0xFFF56C73)),
              const Spacer(),
              Text(
                '$roommatesCount coinquilini gia\npresenti',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textMutedLight,
                  fontSize: 13,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoommateAvatar extends StatelessWidget {
  const _RoommateAvatar({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.p40,
      height: AppSizes.p40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.inputFillDark,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrimaryEnterButton extends StatelessWidget {
  const _PrimaryEnterButton({required this.houseName});

  final String houseName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.p58,
      child: FilledButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const HubCasaAdminScreen()),
            (route) => false,
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandSecondary,
          foregroundColor: AppColors.textOnDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius15),
            side: const BorderSide(color: AppColors.primaryBorder, width: 2),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Entra in $houseName',
            maxLines: 1,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.p56,
      child: OutlinedButton(
        onPressed: Navigator.of(context).pop,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandAccent,
          side: const BorderSide(color: AppColors.brandAccent, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius15),
          ),
        ),
        child: const Text(
          'Annulla',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
