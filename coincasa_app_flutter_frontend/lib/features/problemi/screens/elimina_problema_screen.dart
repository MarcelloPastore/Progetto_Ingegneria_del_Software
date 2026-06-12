import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/problemi/screens/problemi_home_screen.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class EliminaProblemaScreen extends StatefulWidget {
  const EliminaProblemaScreen({super.key});

  static const String routeName = '/problemi/elimina';

  @override
  State<EliminaProblemaScreen> createState() => _EliminaProblemaScreenState();
}

class _EliminaProblemaScreenState extends State<EliminaProblemaScreen> {
  _DeleteState _state = _DeleteState.confirm;
  bool _deleting = false;

  Future<void> _delete(Problema problema) async {
    if (_deleting) return;
    setState(() => _deleting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    mockProblemi.removeWhere((p) => p.id == problema.id);
    if (mounted) setState(() { _deleting = false; _state = _DeleteState.success; });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    Problema? problema;
    if (args is Problema) problema = args;

    if (problema == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: Text('Problema non disponibile', style: AppTextStyles.bodyStrong)),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF6F6C78),
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/problemi'),
        body: SafeArea(
          child: Stack(
            children: [
              // Background content — bloccato ai touch quando il popup è visibile
              AbsorbPointer(
                absorbing: true,
                child: Opacity(
                  opacity: 0.35,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BackTitle(
                          title: 'Dettaglio problema',
                          onBack: () {},
                        ),
                        const SizedBox(height: 50),
                        Text(
                          problema.titolo,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.screenTitleStrong.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${problema.priorita} · ${problema.stato}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFC1BFC8),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _ProblemaInfoCard(problema: problema),
                      ],
                    ),
                  ),
                ),
              ),

              // Barrier scuro + card centrata
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.52),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: switch (_state) {
                      _DeleteState.confirm => _ConfirmDeleteCard(
                          problema: problema,
                          deleting: _deleting,
                          onDelete: () => _delete(problema!),
                          onCancel: () => Navigator.of(context).pop(),
                        ),
                      _DeleteState.success => _DeleteSuccessCard(problema: problema),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay cards
// ---------------------------------------------------------------------------

class _ConfirmDeleteCard extends StatelessWidget {
  const _ConfirmDeleteCard({
    required this.problema,
    required this.deleting,
    required this.onDelete,
    required this.onCancel,
  });

  final Problema problema;
  final bool deleting;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(38, 18, 38, 30),
      decoration: _cardDecoration(const Color(0xFF2D293B)),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 29,
            backgroundColor: Color(0xFFFF7075),
            child: Icon(Icons.delete_rounded, color: Color(0xFF5A141D), size: 34),
          ),
          const SizedBox(height: 18),
          const Text(
            'Eliminare il problema?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Text(
            '"${problema.titolo}" verrà rimosso definitivamente. Tutti i coinquilini verranno avvisati.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFC1BFC8), fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 26),
          _DangerButton(
            label: deleting ? 'Eliminazione...' : 'Sì, elimina definitivamente',
            onPressed: deleting ? null : onDelete,
          ),
          const SizedBox(height: 10),
          _PurpleOutlineButton(label: 'Annulla', onPressed: onCancel),
        ],
      ),
    );
  }
}

class _DeleteSuccessCard extends StatelessWidget {
  const _DeleteSuccessCard({required this.problema});
  final Problema problema;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 374),
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 30),
      decoration: _cardDecoration(const Color(0xFF45FF58)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✓', style: TextStyle(fontSize: 100, height: 1)),
          const SizedBox(height: 10),
          const Text(
            'Problema eliminato',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            '"${problema.titolo}" è stato eliminato con successo.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFC1BFC8), fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 56),
          _PurpleOutlineButton(
            label: 'Torna ai problemi',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/problemi'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info card (riepilogo problema)
// ---------------------------------------------------------------------------

class _ProblemaInfoCard extends StatelessWidget {
  const _ProblemaInfoCard({required this.problema});
  final Problema problema;

  @override
  Widget build(BuildContext context) {
    final descrizione = (problema.raw['descrizione'] as String?)?.trim();
    final segnalatoDa = (problema.raw['segnalatoDa'] as String?)?.trim();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC1BFC8), width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        children: [
          if (descrizione != null && descrizione.isNotEmpty) ...[
            _InfoRow(label: 'Descrizione', value: descrizione),
            const Divider(color: Color(0xFFB8B5C1)),
          ],
          _InfoRow(label: 'Priorità', value: problema.priorita),
          if (segnalatoDa != null && segnalatoDa.isNotEmpty) ...[
            const Divider(color: Color(0xFFB8B5C1)),
            _InfoRow(label: 'Segnalato da', value: segnalatoDa),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Color(0xFFC1BFC8), fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets (same pattern as elimina_spesa)
// ---------------------------------------------------------------------------

class _BackTitle extends StatelessWidget {
  const _BackTitle({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back, color: AppColors.brandAccent, size: 28),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
      const SizedBox(width: 6),
      Text(
        title,
        style: AppTextStyles.screenTitleStrong.copyWith(
          color: AppColors.brandAccent,
          fontSize: 23,
          fontWeight: FontWeight.w800,
        ),
      ),
    ]);
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF3B44), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFFF3B44), fontSize: 21, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _PurpleOutlineButton extends StatelessWidget {
  const _PurpleOutlineButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.brandPrimary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.brandPrimary, fontSize: 21, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

enum _DeleteState { confirm, success }

BoxDecoration _cardDecoration(Color borderColor) => BoxDecoration(
      color: AppColors.darkBackground,
      border: Border.all(color: borderColor, width: 2),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3))],
    );
