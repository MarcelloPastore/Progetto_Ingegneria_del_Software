import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'carica_documenti.dart'; // ← import corretto senza "s"

class ArchivioDocumentiVuotoScreen extends StatelessWidget {
  const ArchivioDocumentiVuotoScreen({super.key});

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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                          'Documenti',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Image.asset(
                    'assets/Icons/png-clipart-rectangle-generic-black-folder-black-file-holder-angle-rectangle-thumbnail 1.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.folder_open_rounded,
                      size: 96,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Archivio vuoto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nessun documento ancora. Solo\nl\'Amministratore può caricare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD7D3E8),
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CaricaDocumentoScreen(),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Carica documento',
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
            Positioned(
              right: 24,
              bottom: 30,
              child: FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaricaDocumentoScreen(),
                  ),
                ),
                backgroundColor: AppColors.brandPrimary,
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _DocumentsBottomNav(),
    );
  }
}

class _DocumentsBottomNav extends StatelessWidget {
  const _DocumentsBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Color(0xFF17213B),
        border: Border(top: BorderSide(color: Color(0xFF263552), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            iconPath: 'assets/Icons/home.png',
            label: 'Home',
            active: true,
          ),
          _NavItem(iconPath: 'assets/Icons/spese.png', label: 'Spese'),
          _NavItem(iconPath: 'assets/Icons/turni.png', label: 'Turni'),
          _NavItem(iconPath: 'assets/Icons/reminder.png', label: 'Scadenze'),
          _NavItem(iconPath: 'assets/Icons/problemi.png', label: 'Problemi'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool active;

  const _NavItem({
    required this.iconPath,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 27, height: 27, fit: BoxFit.contain),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppColors.brandPrimary : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
