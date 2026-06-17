import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
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
      icona: '',
    ),
    _Documento(
      nome: 'Bolletta gas',
      tipo: 'PDF',
      icona: '',
    ),
    _Documento(
      nome: 'Scontrino spesa',
      tipo: 'IMG',
      icona: '',
    ),
  ];

  Future<void> _elimina(int index) async {
    final confermato = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151127),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Elimina documento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Sei sicuro di voler eliminare "${_documenti[index].nome}"? Questa azione non può essere annullata.',
          style: const TextStyle(color: Color(0xFFD7D3E8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annulla',
              style: TextStyle(color: AppColors.brandAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Elimina',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confermato == true) {
      setState(() => _documenti.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento eliminato correttamente')),
        );
      }
    }
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
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
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

          ],
        ),
      ),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
    );
  }
}

class _DocRow extends StatelessWidget {
  final _Documento doc;
  final VoidCallback onElimina;

  const _DocRow({required this.doc, required this.onElimina});

  @override
  Widget build(BuildContext context) {
    final isPdf = doc.tipo == 'PDF';
    final mainColor = isPdf ? Colors.red : Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mainColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: mainColor,
                size: 24,
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
          IconButton(
            onPressed: onElimina,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFF75C6C), // Rosso coordinato con il resto dell'app
              size: 24,
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


