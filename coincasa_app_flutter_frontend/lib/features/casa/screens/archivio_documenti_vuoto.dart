import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'carica_documenti.dart';

class ArchivioDocumentiVuotoScreen extends StatelessWidget {
  const ArchivioDocumentiVuotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p20,
                AppSizes.p18,
                AppSizes.p20,
                AppSizes.p104,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.textOnDark,
                          size: AppSizes.p20,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Documenti',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: AppSizes.p18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.p48),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p56),
                  Image.asset(
                    'assets/Icons/home_auth_icon.png',
                    width: AppSizes.p96,
                    height: AppSizes.p96,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.folder_open_rounded,
                      size: AppSizes.p96,
                      color: AppColors.keyYellow,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p22),
                  const Text(
                    'Archivio vuoto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: AppSizes.p18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  const Text(
                    'Nessun documento ancora. Solo\nl\'Amministratore può caricare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textOnDarkMuted,
                      fontSize: AppSizes.p13,
                      height: AppSizes.p1_15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p36),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10),
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CaricaDocumentoScreen(),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(AppSizes.p45),
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.textOnDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius9),
                        ),
                      ),
                      child: const Text(
                        'Carica documento',
                        style: TextStyle(
                          fontSize: AppSizes.p17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
    );
  }
}
