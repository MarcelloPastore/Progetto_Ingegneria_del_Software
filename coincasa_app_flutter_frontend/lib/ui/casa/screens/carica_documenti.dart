import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'archivio_documenti.dart';

class CaricaDocumentoScreen extends StatefulWidget {
  const CaricaDocumentoScreen({super.key});

  @override
  State<CaricaDocumentoScreen> createState() => _CaricaDocumentoScreenState();
}

class _CaricaDocumentoScreenState extends State<CaricaDocumentoScreen> {
  String? _selectedFile;
  final _nomeCtrl = TextEditingController();

  bool get _canUpload => ApiProvider.client.isHomeAdmin;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.brandPrimary,
                          size: AppSizes.p28,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Carica documento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: AppSizes.p18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: AppSizes.p4),
                        child: Image.asset(
                          'assets/Icons/Profilo_utente_icona.png',
                          width: AppSizes.p32,
                          height: AppSizes.p32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p24),

                  if (_canUpload) ...[
                    GestureDetector(
                      onTap: () => setState(
                        () => _selectedFile = 'Contratto_affitto_2026.pdf',
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.p32,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(AppSizes.radius12),
                          border: Border.all(
                            color: _selectedFile != null
                                ? AppColors.brandAccent
                                : AppColors.brandPrimary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/Icons/reminder.png',
                              width: AppSizes.p72,
                              height: AppSizes.p72,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.folder_open_rounded,
                                    size: AppSizes.p72,
                                    color: AppColors.keyYellow,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.p12),
                            Text(
                              _selectedFile ?? 'Seleziona file',
                              style: const TextStyle(
                                color: AppColors.brandAccent,
                                fontSize: AppSizes.p16,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.brandAccent,
                              ),
                            ),
                            const SizedBox(height: AppSizes.p6),
                            const Text(
                              'PDF, JPG, PNG - max\n10 MB',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textOnDarkMuted,
                                fontSize: AppSizes.p13,
                                fontWeight: FontWeight.w500,
                                height: AppSizes.p1_3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p20),

                    const Text(
                      'Nome documento (opzionale)',
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: AppSizes.p14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p8),
                    TextField(
                      controller: _nomeCtrl,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: AppSizes.p14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'es. Contratto affitto 2025',
                        hintStyle: const TextStyle(
                          color: AppColors.brandAccent,
                          fontSize: AppSizes.p13,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius9),
                          borderSide: const BorderSide(
                            color: AppColors.brandAccent,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius9),
                          borderSide: const BorderSide(
                            color: AppColors.brandAccent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p14,
                          vertical: AppSizes.p13,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p12),

                    const Text(
                      'Il documento sarà visibile a tutti i coinquilini.\nSolo gli Admin possono eliminarlo',
                      style: TextStyle(
                        color: AppColors.textOnDarkMuted,
                        fontSize: AppSizes.p13,
                        fontWeight: FontWeight.w500,
                        height: AppSizes.p1_3,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p28),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10),
                      child: FilledButton(
                        onPressed: _selectedFile != null
                            ? () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ArchivioDocumentiScreen(),
                                ),
                              )
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSizes.p45),
                          backgroundColor: AppColors.brandAccent,
                          disabledBackgroundColor: AppColors.disabledButtonFill,
                          foregroundColor: AppColors.darkBackground,
                          disabledForegroundColor: AppColors.disabledButtonForeground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radius9),
                          ),
                        ),
                        child: const Text(
                          'Carica',
                          style: TextStyle(
                            fontSize: AppSizes.p17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: AppColors.brandAccent,
                            size: AppSizes.p64,
                          ),
                          SizedBox(height: AppSizes.p16),
                          Text(
                            'Accesso limitato',
                            style: TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: AppSizes.p20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSizes.p8),
                          Text(
                            'Solo gli Admin possono caricare documenti.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textOnDarkMuted,
                              fontSize: AppSizes.p16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                  const SizedBox(height: AppSizes.p10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(AppSizes.p45),
                        foregroundColor: AppColors.brandAccent,
                        side: const BorderSide(
                          color: AppColors.brandAccent,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius9),
                        ),
                      ),
                      child: Text(
                        _canUpload ? 'Annulla' : 'Torna indietro',
                        style: const TextStyle(
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
