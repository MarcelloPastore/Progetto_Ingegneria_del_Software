import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coincasa_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class CasaCreataSuccessoScreen extends StatelessWidget {
  final String name;
  final String inviteCode;
  final int validDays;

  const CasaCreataSuccessoScreen({
    super.key,
    required this.name,
    required this.inviteCode,
    this.validDays = 7,
  });

  @override
  Widget build(BuildContext context) {
    final houseName = name.trim();
    final displayedInviteCode = inviteCode.trim().isEmpty
        ? 'Codice non disponibile'
        : inviteCode.trim();
    final title = houseName.isEmpty
        ? 'Casa Creata!'
        : '${houseName.toLowerCase().startsWith('casa ') ? houseName : 'Casa $houseName'} Creata!';

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
                      horizontal: AppSizes.p20,
                      vertical: AppSizes.p24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/Icons/green_check_mark.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppSizes.p24),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.screenTitleStrong,
                        ),
                        const SizedBox(height: AppSizes.p12),
                        const Text(
                          'Sei l\'Amministratore della casa.\nCondividi il codice con i tuoi coinquilini',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.errorCompact,
                        ),
                        const SizedBox(height: AppSizes.p28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.p20,
                            vertical: AppSizes.p20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radius24,
                            ),
                            border: Border.all(
                              color: AppColors.dividerDark,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Codice invito',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.dashboardCardLabel,
                              ),
                              const SizedBox(height: AppSizes.p16),
                              SizedBox(
                                width: double.infinity,
                                height: AppSizes.p56,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSizes.p56,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          displayedInviteCode,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles
                                              .dashboardBalanceAmount
                                              .copyWith(
                                                color: AppColors.textOnDark,
                                                fontSize: 28,
                                                letterSpacing: 2,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radius12,
                                        ),
                                        onTap: () => _copyInviteCode(context),
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            AppSizes.p12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceDarkElevated,
                                            borderRadius: BorderRadius.circular(
                                              AppSizes.radius12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.copy,
                                            color: AppColors.brandPrimary,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSizes.p8),
                              Text(
                                'valido per $validDays giorni',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.dashboardCardLabel,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.p28),
                        FilledButton(
                          onPressed: () => _copyInviteCode(context),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppSizes.p56),
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: AppColors.textOnDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius16,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Condividi codice',
                            style: AppTextStyles.buttonCompact,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p12),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                builder: (_) => const DashboardScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppSizes.p56),
                            side: const BorderSide(color: AppColors.brandPrimary),
                            foregroundColor: AppColors.textOnDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius16,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Vai alla Dashboard',
                            style: AppTextStyles.buttonCompact,
                          ),
                        ),
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

  Future<void> _copyInviteCode(BuildContext context) async {
    final code = inviteCode.trim();
    if (code.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Codice copiato negli appunti'),
          backgroundColor: AppColors.brandPrimary,
        ),
      );
  }
}
