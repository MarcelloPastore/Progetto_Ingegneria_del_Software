import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'archivio_documenti.dart'; // ← import corretto

class CaricaDocumentoScreen extends StatefulWidget {
  const CaricaDocumentoScreen({super.key});

  @override
  State<CaricaDocumentoScreen> createState() => _CaricaDocumentoScreenState();
}

class _CaricaDocumentoScreenState extends State<CaricaDocumentoScreen> {
  String? _selectedFile;
  final _nomeCtrl = TextEditingController();

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09031F),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
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
                          size: 28,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Carica documento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Image.asset(
                          'assets/Icons/Profilo_utente_icona.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () => setState(
                      () => _selectedFile = 'Contratto_affitto_2026.pdf',
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151127),
                        borderRadius: BorderRadius.circular(12),
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
                            width: 72,
                            height: 72,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.folder_open_rounded,
                                  size: 72,
                                  color: Color(0xFFFFB300),
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFile ?? 'Seleziona file',
                            style: const TextStyle(
                              color: AppColors.brandAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.brandAccent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'PDF, JPG, PNG - max\n10 MB',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFD7D3E8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Nome documento (opzionale)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nomeCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'es. Contratto affitto 2025',
                      hintStyle: const TextStyle(
                        color: AppColors.brandAccent,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF151127),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: AppColors.brandAccent,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: AppColors.brandAccent,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Il documento sarà visibile a tutti i coinquilini.\nSolo gli Admin possono eliminarlo',
                    style: TextStyle(
                      color: Color(0xFFD7D3E8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FilledButton(
                      onPressed: _selectedFile != null
                          ? () => Navigator.pushReplacement(
                              // ← va ad ArchivioDocumentiScreen
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ArchivioDocumentiScreen(),
                              ),
                            )
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                        backgroundColor: AppColors.brandAccent,
                        disabledBackgroundColor: AppColors.brandAccent
                            .withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Carica',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                        foregroundColor: AppColors.brandAccent,
                        side: const BorderSide(
                          color: AppColors.brandAccent,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Annulla',
                        style: TextStyle(
                          fontSize: 17,
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


