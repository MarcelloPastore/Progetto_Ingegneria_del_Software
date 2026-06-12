import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/problemi/screens/deassegnazione_successo_screen.dart';
import 'package:coincasa_app/features/problemi/screens/problemi_home_screen.dart';

// ---------------------------------------------------------------------------
// Entry point: mostra il dettaglio come modal bottom sheet
// ---------------------------------------------------------------------------

Future<void> showProblemaDettaglio(BuildContext context, Problema problema) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: _ProblemaDettaglioSheet(problema: problema),
    ),
  );
}

// ---------------------------------------------------------------------------
// Manteniamo la route per compatibilità con navigazione esistente
// ---------------------------------------------------------------------------

class ProblemaDettaglioScreen extends StatelessWidget {
  const ProblemaDettaglioScreen({super.key});

  static const String routeName = '/problemi/dettaglio';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    Problema? problema;
    if (args is Problema) {
      problema = args;
    } else if (args is Map<String, dynamic>) {
      problema = Problema.fromJson(args);
    } else if (args is Map) {
      problema = Problema.fromJson(Map<String, dynamic>.from(args));
    }

    if (problema == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: Text('Problema non disponibile', style: AppTextStyles.bodyStrong)),
      );
    }

    // Apre immediatamente il sheet e torna indietro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showProblemaDettaglio(context, problema!).then((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    });
    return const Scaffold(backgroundColor: AppColors.darkBackground);
  }
}

// ---------------------------------------------------------------------------
// Sheet interno
// ---------------------------------------------------------------------------

class _ProblemaDettaglioSheet extends StatefulWidget {
  const _ProblemaDettaglioSheet({required this.problema});
  final Problema problema;

  @override
  State<_ProblemaDettaglioSheet> createState() => _ProblemaDettaglioSheetState();
}

class _ProblemaDettaglioSheetState extends State<_ProblemaDettaglioSheet> {
  final LayerLink _priorityMenuLink = LayerLink();
  OverlayEntry? _priorityOverlay;
  bool _menuScheduled = false;
  bool _isProcessing = false;
  late String? _priorityOverride;

  @override
  void initState() {
    super.initState();
    _priorityOverride = widget.problema.priorita;
  }

  @override
  void dispose() {
    _hidePriorityMenu();
    super.dispose();
  }

  String get _priorityLabel {
    final value = (_priorityOverride ?? widget.problema.priorita).trim();
    final lower = value.toLowerCase();
    if (lower.contains('urg')) return 'Urgente';
    if (lower.contains('med')) return 'Media';
    if (lower.contains('bass')) return 'Bassa';
    return value.isEmpty ? 'Media' : value;
  }

  bool get _isCurrentUserAssignee {
    final problema = widget.problema;
    final currentId = ApiProvider.client.currentUserId?.trim();
    final rawAssigneeId = _firstString([
      problema.raw['assegnatarioId'],
      problema.raw['assegnatario_id'],
      problema.raw['idAssegnatario'],
      problema.raw['responsabileId'],
      problema.raw['responsabile_id'],
    ]);
    if (currentId != null && currentId.isNotEmpty && rawAssigneeId == currentId) return true;
    final currentName = ApiProvider.client.currentUserName?.trim().toLowerCase();
    final assigneeName = _rawResponsabileNome(problema)?.trim().toLowerCase();
    return currentName != null && currentName.isNotEmpty && assigneeName == currentName;
  }

  String? _rawResponsabileNome(Problema problema) {
    return _firstString([
      problema.raw['assegnatarioNome'],
      problema.raw['assegnatario_nome'],
      problema.raw['responsabileNome'],
      problema.raw['responsabile_nome'],
      problema.raw['assegnatario'],
      problema.raw['responsabile'],
    ]);
  }

  String? _responsabileNome(Problema problema) {
    final name = _rawResponsabileNome(problema);
    if (name != null && name.trim().isNotEmpty) return name.trim();
    if (_isCurrentUserAssignee) return ApiProvider.client.currentUserName;
    return null;
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  bool get _isCreator {
    final problema = widget.problema;
    final currentId = ApiProvider.client.currentUserId?.trim();
    final rawCreatorId = _firstString([
      problema.raw['creatoreId'],
      problema.raw['autoreId'],
      problema.raw['segnalatoDaId'],
      problema.raw['createdBy'],
    ]);
    if (currentId != null && currentId.isNotEmpty && rawCreatorId == currentId) return true;
    final currentName = ApiProvider.client.currentUserName?.trim().toLowerCase();
    final rawCreatorName = _firstString([
      problema.raw['segnalatoDa'],
      problema.raw['autore'],
      problema.raw['createdByName'],
    ])?.trim().toLowerCase();
    return currentName != null && currentName.isNotEmpty && currentName == rawCreatorName;
  }

  Future<void> _handleDeassignProblema() async {
    final problema = widget.problema;
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final index = mockProblemi.indexWhere((p) => p.id == problema.id);
    if (index != -1) {
      mockProblemi[index] = Problema(
        id: problema.id,
        titolo: problema.titolo,
        stato: 'Segnalato',
        priorita: problema.priorita,
        raw: Map<String, dynamic>.from(problema.raw)
          ..remove('assegnatarioNome')
          ..remove('assegnatario_nome')
          ..remove('assegnatario'),
      );
    }
    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed(DeassegnazioneSuccessoScreen.routeName);
    }
  }

  Future<void> _handleAssignMe() async {
    final problema = widget.problema;
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final index = mockProblemi.indexWhere((p) => p.id == problema.id);
    if (index != -1) {
      mockProblemi[index] = Problema(
        id: problema.id,
        titolo: problema.titolo,
        stato: 'Assegnato',
        priorita: _priorityOverride ?? problema.priorita,
        raw: Map<String, dynamic>.from(problema.raw)
          ..['assegnatarioNome'] = ApiProvider.client.currentUserName ?? 'Tu',
      );
    }
    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ti sei preso in carico il problema!')),
      );
    }
  }

  void _showRinunciaDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chiudi',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C192E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.warning, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text('De-assegnazione', style: AppTextStyles.bodyStrong.copyWith(color: AppColors.warning, fontSize: 22, fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: 20),
                Text(
                  'Se rinunci al problema, tornerà allo stato Segnalato e tutti i coinquilini verranno avvisati',
                  style: TextStyle(color: AppColors.warning.withValues(alpha: 0.9), fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Annulla', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w700)),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(
                    onPressed: () { Navigator.of(context).pop(); _handleDeassignProblema(); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: const Text('Conferma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problema = widget.problema;
    final isSegnalato = problema.stato.toLowerCase().contains('segna');
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: _hidePriorityMenu,
      behavior: HitTestBehavior.translucent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close handle + X button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  child: isSegnalato ? _buildSegnalatoContent(problema) : _buildAssegnatoContent(problema),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vista segnalato ────────────────────────────────────────────────────────

  Widget _buildSegnalatoContent(Problema problema) {
    final titleColor = _priorityForeground(_priorityLabel);
    final reportedBy = _firstString([problema.raw['segnalatoDa'], problema.raw['autore']]) ?? 'Marco';
    const reportedAt = '09:15 - 20 apr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF2D293B), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF75C6C), size: 30),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Nuovo problema\nsegnalato', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
            ),
            _StatusPill(label: _priorityLabel, background: _priorityBackground(_priorityLabel), foreground: Colors.white),
          ],
        ),
        const SizedBox(height: 8),
        Text(problema.titolo, style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
        const SizedBox(height: 28),

        // Modifica Priorità
        const Text('Modifica Priorità', style: TextStyle(color: Color(0xFF8A72D9), fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Row(children: [
          _PriorityButton(label: 'Urgente', dotColor: const Color(0xFFE53935), color: const Color(0xFFBE2C2C), isSelected: _priorityLabel == 'Urgente', onTap: () => setState(() => _priorityOverride = 'Urgente')),
          const SizedBox(width: 10),
          _PriorityButton(label: 'Media', dotColor: const Color(0xFFFF8C00), color: const Color(0xFF7B4508), isSelected: _priorityLabel == 'Media', onTap: () => setState(() => _priorityOverride = 'Media')),
          const SizedBox(width: 10),
          _PriorityButton(label: 'Bassa', dotColor: const Color(0xFFD4AC00), color: const Color(0xFF806600), isSelected: _priorityLabel == 'Bassa', onTap: () => setState(() => _priorityOverride = 'Bassa')),
        ]),
        const SizedBox(height: 28),

        // Dettagli
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3F4A72), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DETTAGLI PROBLEMA', style: TextStyle(color: Color(0xFF8A72D9), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
              const SizedBox(height: 14),
              Text(_resolveDescription(problema), style: const TextStyle(color: Color(0xFFC6C1CC), fontSize: 16, height: 1.5)),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF3F4A72), thickness: 1, height: 1),
              const SizedBox(height: 18),
              Row(children: [
                const Text('Segnalato da', style: TextStyle(color: Color(0xFF8A72D9), fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                _AssigneeAvatar(name: reportedBy),
                const SizedBox(width: 10),
                Text(reportedBy, style: const TextStyle(color: Color(0xFFC6C1CC), fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF3F4A72), thickness: 1, height: 1),
              const SizedBox(height: 18),
              Row(children: [
                const Text('Ore', style: TextStyle(color: Color(0xFF8A72D9), fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Text(reportedAt, style: TextStyle(color: Color(0xFF8C8C96), fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Disponibilità
        const Text('SEI DISPONIBILE?', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFC6C1CC), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 14),
        _AvailabilityButton(
          label: 'Sì, me ne occupo io',
          icon: Icons.front_hand_rounded,
          gradient: const LinearGradient(colors: [Color(0xFF3F961A), Color(0xFF2D6A12)]),
          outlined: true,
          onTap: _isProcessing ? null : _handleAssignMe,
        ),
        const SizedBox(height: 12),
        _AvailabilityButton(
          label: 'Non posso, passa ad altri',
          icon: Icons.people_alt_outlined,
          color: const Color(0xFF2D293B),
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // ── Vista assegnato ────────────────────────────────────────────────────────

  Widget _buildAssegnatoContent(Problema problema) {
    final assigneeName = _responsabileNome(problema) ?? 'Francesco';
    final historyEvents = _historyEvents(problema);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Titolo + pill stato
        Text(problema.titolo, style: AppTextStyles.screenTitleStrong.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          _StatusPill(label: 'Assegnato', background: AppColors.warning.withValues(alpha: 0.22), foreground: AppColors.warning),
          const SizedBox(width: 8),
          CompositedTransformTarget(
            link: _priorityMenuLink,
            child: InkWell(
              onTap: _togglePriorityMenu,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _priorityBackground(_priorityLabel),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _priorityForeground(_priorityLabel).withValues(alpha: 0.55)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_priorityLabel, style: TextStyle(color: _priorityForeground(_priorityLabel), fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 2),
                  Icon(_priorityOverlay == null ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded, color: _priorityForeground(_priorityLabel), size: 20),
                ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _DetailCard(
          title: _isCurrentUserAssignee ? 'Responsabile (tu)' : 'Responsabile',
          child: Row(children: [
            _AssigneeAvatar(name: assigneeName),
            const SizedBox(width: 12),
            Expanded(child: Text(assigneeName, style: AppTextStyles.screenTitleStrong.copyWith(color: AppColors.textMutedLight, fontSize: 18))),
          ]),
        ),
        const SizedBox(height: 16),
        _DetailCard(
          title: 'Descrizione problema',
          child: Text(_resolveDescription(problema), style: AppTextStyles.bodyMutedRelaxed.copyWith(color: AppColors.textMutedLight, fontSize: 16)),
        ),
        const SizedBox(height: 16),
        _DetailCard(
          title: 'Storico stato',
          child: Column(children: [
            for (var i = 0; i < historyEvents.length; i++) ...[
              _StatusHistoryRow(event: historyEvents[i]),
              if (i != historyEvents.length - 1) const SizedBox(height: 14),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        _DangerActionButton(label: 'Rinuncia al problema', color: const Color(0xFFBE2C2C), shadowColor: const Color(0xFFBE2C2C), onPressed: _isProcessing ? null : _showRinunciaDialog),
        const SizedBox(height: 12),
        _DangerActionButton(label: 'Segna come risolto', color: const Color(0xFF3F961A), shadowColor: const Color(0xFF3F961A), onPressed: () {}),
        if (_isCreator) ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _OutlineActionButton(label: 'Modifica', icon: Icons.edit_rounded, onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pushNamed('/problemi/segnala', arguments: widget.problema); })),
            const SizedBox(width: 12),
            Expanded(child: _OutlineActionButton(label: 'Elimina', icon: Icons.delete_outline_rounded, color: const Color(0xFFBE2C2C), onPressed: () {})),
          ]),
        ],
      ],
    );
  }

  void _togglePriorityMenu() {
    if (_priorityOverlay != null) _hidePriorityMenu(); else _showPriorityMenu();
  }

  void _showPriorityMenu() {
    if (_priorityOverlay != null || _menuScheduled) return;
    _menuScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _menuScheduled = false;
      if (!mounted || _priorityOverlay != null) return;
      _priorityOverlay = OverlayEntry(
        builder: (context) => Stack(children: [
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _hidePriorityMenu, child: Container(color: Colors.transparent))),
          CompositedTransformFollower(
            link: _priorityMenuLink,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 6),
            child: _PriorityMenu(onSelected: (value) { setState(() => _priorityOverride = value); _hidePriorityMenu(); }),
          ),
        ]),
      );
      Overlay.of(context).insert(_priorityOverlay!);
    });
  }

  void _hidePriorityMenu() {
    _priorityOverlay?.remove();
    _priorityOverlay = null;
  }

  List<_StatusEvent> _historyEvents(Problema problema) {
    final events = <_StatusEvent>[];
    events.add(_StatusEvent(label: 'Segnalato', detail: 'Segnalazione registrata', color: AppColors.statusNegative));
    if (problema.stato.toLowerCase().contains('assegn')) {
      events.add(_StatusEvent(label: 'Assegnato', detail: 'Assegnazione completata', color: AppColors.problemPriorityMedium));
    }
    return events;
  }

  String _resolveDescription(Problema problema) {
    return _firstString([problema.raw['descrizione'], problema.raw['messaggio']]) ?? 'Nessuna descrizione disponibile.';
  }

  Color _priorityBackground(String label) {
    switch (label.toLowerCase()) {
      case 'urgente': return const Color(0xFF6B1B1B);
      case 'media': return const Color(0xFF7B4508);
      default: return const Color(0xFF806600);
    }
  }

  Color _priorityForeground(String label) {
    switch (label.toLowerCase()) {
      case 'urgente': return AppColors.problemPriorityUrgent;
      case 'media': return AppColors.problemPriorityMedium;
      default: return AppColors.problemPriorityLow;
    }
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.background, required this.foreground});
  final String label; final Color background; final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
    child: Text(label, style: TextStyle(color: foreground, fontSize: 14, fontWeight: FontWeight.w800)),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});
  final String title; final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surfaceDarkElevated.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.screenTitleStrong.copyWith(color: AppColors.brandAccent, fontSize: 17)),
      const SizedBox(height: 10),
      child,
    ]),
  );
}

class _AssigneeAvatar extends StatelessWidget {
  const _AssigneeAvatar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(color: const Color(0xFF304A7E), shape: BoxShape.circle, border: Border.all(color: AppColors.brandAccent, width: 1.4)),
    child: Center(child: Text(_initials(name), style: const TextStyle(color: Color(0xFF85A7F0), fontSize: 14, fontWeight: FontWeight.w800))),
  );
  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _StatusHistoryRow extends StatelessWidget {
  const _StatusHistoryRow({required this.event});
  final _StatusEvent event;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(top: 5), child: Container(width: 12, height: 12, decoration: BoxDecoration(color: event.color, shape: BoxShape.circle))),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(event.label, style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textMutedLight, fontSize: 15)),
      Text(event.detail, style: AppTextStyles.bodyMuted.copyWith(color: AppColors.textMutedDark, fontSize: 13)),
    ])),
  ]);
}

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({required this.label, required this.color, required this.shadowColor, this.onPressed});
  final String label; final Color color; final Color shadowColor; final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Text(label, style: AppTextStyles.buttonCompact.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
    ),
  );
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({required this.label, required this.icon, this.color, this.onPressed});
  final String label; final IconData icon; final Color? color; final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brandAccent;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: c),
      label: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _PriorityMenu extends StatelessWidget {
  const _PriorityMenu({required this.onSelected});
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      width: 150,
      decoration: BoxDecoration(color: AppColors.surfaceDarkElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.4))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _PriorityMenuItem(label: 'Urgente', icon: Icons.priority_high_rounded, color: AppColors.problemPriorityUrgent, onTap: () => onSelected('Urgente')),
        const Divider(height: 1, thickness: 1, color: AppColors.dividerOnDark),
        _PriorityMenuItem(label: 'Media', icon: Icons.drag_handle_rounded, color: AppColors.problemPriorityMedium, onTap: () => onSelected('Media')),
        _PriorityMenuItem(label: 'Bassa', icon: Icons.low_priority_rounded, color: AppColors.problemPriorityLow, onTap: () => onSelected('Bassa')),
      ]),
    ),
  );
}

class _PriorityMenuItem extends StatelessWidget {
  const _PriorityMenuItem({required this.label, required this.icon, required this.color, required this.onTap});
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700))])),
  );
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({required this.label, required this.color, required this.dotColor, required this.isSelected, required this.onTap});
  final String label; final Color color; final Color dotColor; final bool isSelected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isSelected ? 1.0 : 0.35),
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
      ),
    ),
  );
}

class _AvailabilityButton extends StatelessWidget {
  const _AvailabilityButton({required this.label, required this.icon, this.gradient, this.color, this.outlined = false, this.onTap});
  final String label; final IconData icon; final Gradient? gradient; final Color? color; final bool outlined; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: outlined ? Border.all(color: const Color(0xFF5CDD28), width: 2.5) : null,
        boxShadow: outlined ? [BoxShadow(color: const Color(0xFF3F961A).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 22),
        Expanded(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
        const SizedBox(width: 22),
      ]),
    ),
  );
}

class _StatusEvent {
  const _StatusEvent({required this.label, required this.detail, required this.color});
  final String label; final String detail; final Color color;
}

// Keep DetailActionsBar export-compatible (used by altri file se presenti)
class DetailActionsBar extends StatelessWidget {
  const DetailActionsBar({super.key, required this.modifyLabel, required this.deleteLabel, required this.isCreator, required this.onModify, required this.onDelete});
  final String modifyLabel; final String deleteLabel; final bool isCreator; final VoidCallback onModify; final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
