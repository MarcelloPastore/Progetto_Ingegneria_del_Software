import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'carica_documenti.dart'; // ← import corretto senza "s"

class ArchivioDocumentiScreen extends StatefulWidget {
  const ArchivioDocumentiScreen({super.key});

  @override
  State<ArchivioDocumentiScreen> createState() =>
      _ArchivioDocumentiScreenState();
}

class _ArchivioDocumentiScreenState extends State<ArchivioDocumentiScreen> {
  final List<_Documento> _documenti = [
    _Documento(
      nome: 'Contratto affitto',
      tipo: 'PDF',
      icona: 'assets/Icons/images 5.png',
    ),
    _Documento(
      nome: 'Bolletta gas',
      tipo: 'PDF',
      icona: 'assets/Icons/images 5.png',
    ),
    _Documento(
      nome: 'Scontrino spesa',
      tipo: 'IMG',
      icona: 'assets/Icons/images 6.png',
    ),
  ];

  void _elimina(int index) {
    setState(() => _documenti.removeAt(index));
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
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151127),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      border: Border.all(
                        color: AppColors.brandAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'ARCHIVIO CONDIVISO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151127),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.brandAccent.withValues(alpha: 0.4),
                        ),
                        right: BorderSide(
                          color: AppColors.brandAccent.withValues(alpha: 0.4),
                        ),
                        bottom: BorderSide(
                          color: AppColors.brandAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _documenti.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.brandAccent.withValues(alpha: 0.2),
                        height: 1,
                      ),
                      itemBuilder: (_, i) => _DocRow(
                        doc: _documenti[i],
                        onElimina: () => _elimina(i),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaricaDocumentoScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: const Text(
                      'Carica documento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.brandAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                backgroundColor: AppColors.brandAccent,
                child: const Icon(Icons.add, size: 28, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _DocumentsBottomNav(),
    );
  }
}

class _DocRow extends StatelessWidget {
  final _Documento doc;
  final VoidCallback onElimina;

  const _DocRow({required this.doc, required this.onElimina});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Image.asset(
            doc.icona,
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: doc.tipo == 'PDF'
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  doc.tipo,
                  style: TextStyle(
                    color: doc.tipo == 'PDF' ? Colors.red : Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'file ${doc.tipo}',
                  style: const TextStyle(
                    color: Color(0xFFD7D3E8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onElimina,
            child: Image.asset(
              'assets/Icons/62945wastebasket_109227 1.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF8B8B8B),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Documento {
  final String nome;
  final String tipo;
  final String icona;

  const _Documento({
    required this.nome,
    required this.tipo,
    required this.icona,
  });
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
              color: active ? AppColors.brandAccent : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
