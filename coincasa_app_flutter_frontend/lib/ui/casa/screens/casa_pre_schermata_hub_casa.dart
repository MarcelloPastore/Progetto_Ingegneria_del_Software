import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/state/active_casa_session.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/domain/viewmodel/dashboard_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/ui/dashboard/screens/dashboard_screen.dart';

class CasaPreSchermataHubCasaScreen extends StatelessWidget {
  const CasaPreSchermataHubCasaScreen({
    super.key,
    required this.houseName,
    this.houseType = '',
    this.city = '',
    this.casaId,
  });

  final String houseName;
  final String houseType;
  final String city;

  /// Id della casa appena joinata — usato per chiamare selectCasa.
  final String? casaId;

  @override
  Widget build(BuildContext context) {
    final displayHouseName = _formatHouseName(houseName);
    final locationText = _formatLocationText(houseType: houseType, city: city);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                        ),
                        const SizedBox(height: AppSizes.p32),
                        _PrimaryEnterButton(
                          houseName: displayHouseName,
                          casaId: casaId,
                        ),
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
  });

  final String houseName;
  final String locationText;

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
        ],
      ),
    );
  }
}

class _PrimaryEnterButton extends ConsumerWidget {
  const _PrimaryEnterButton({required this.houseName, this.casaId});

  final String houseName;
  final String? casaId;

  Future<void> _onEnter(BuildContext context, WidgetRef ref) async {
    final id = casaId;
    if (id != null && id.isNotEmpty) {
      try {
        await ensureActiveCasaContext(
          ActiveCasaScope.read(context),
          preferredCasaId: id,
        );
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile selezionare la casa. Riprova.'),
          ),
        );
        return;
      }
    }
    // Invalida lista case e dashboard così mostrano la nuova casa.
    ref.invalidate(listaCaseViewModelProvider);
    ref.invalidate(dashboardViewModelProvider);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: AppSizes.p58,
      child: FilledButton(
        onPressed: () => _onEnter(context, ref),
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
