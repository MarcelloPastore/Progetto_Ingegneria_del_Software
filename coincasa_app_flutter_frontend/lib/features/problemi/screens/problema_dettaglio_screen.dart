import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/features/problemi/screens/deassegnazione_successo_screen.dart';
import 'package:coincasa_app/features/problemi/screens/modifica_problema_screen.dart';

// ---------------------------------------------------------------------------
// Entry point mantenuto per compatibilità con dashboard_screen
// ---------------------------------------------------------------------------

Future<void> showProblemaDettaglio(BuildContext context, Problema problema) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ProblemaDettaglioScreen._withProblema(problema),
    ),
  );
}

// ---------------------------------------------------------------------------
// Route
// ---------------------------------------------------------------------------

class ProblemaDettaglioScreen extends StatelessWidget {
  const ProblemaDettaglioScreen({super.key}) : _problema = null;

  const ProblemaDettaglioScreen._withProblema(Problema this._problema)
    : super(key: null);

  static const String routeName = '/problemi/dettaglio';

  final Problema? _problema;

  @override
  Widget build(BuildContext context) {
    Problema? problema = _problema;
    if (problema == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Problema) {
        problema = args;
      } else if (args is Map<String, dynamic>) {
        problema = Problema.fromJson(args);
      } else if (args is Map) {
        problema = Problema.fromJson(Map<String, dynamic>.from(args));
      }
    }

    if (problema == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Text(
            'Problema non disponibile',
            style: AppTextStyles.bodyStrong,
          ),
        ),
      );
    }

    return _ProblemaDettaglioPage(problema: problema);
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class _ProblemaDettaglioPage extends StatefulWidget {
  const _ProblemaDettaglioPage({required this.problema});
  final Problema problema;

  @override
  State<_ProblemaDettaglioPage> createState() => _ProblemaDettaglioPageState();
}

class _ProblemaDettaglioPageState extends State<_ProblemaDettaglioPage> {
  bool _isProcessing = false;
  late String _priorityOverride;
  late Problema _problema;

  @override
  void initState() {
    super.initState();
    _problema = widget.problema;
    _priorityOverride = _problema.priorita.isNotEmpty
        ? _problema.priorita
        : 'Media';
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String? _firstString(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final t = v.toString().trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  String get _normalizedPriority {
    final lower = _priorityOverride.toLowerCase();
    if (lower.contains('urg')) return 'Urgente';
    if (lower.contains('med')) return 'Media';
    if (lower.contains('bass')) return 'Bassa';
    return _priorityOverride;
  }

  bool get _isSegnalato => _problema.stato.toLowerCase().contains('segna');

  bool get _isCurrentUserAssignee {
    final problema = _problema;
    final currentId = ApiProvider.client.currentUserId?.trim();
    final rawId = _firstString([
      problema.raw['assegnatarioId'],
      problema.raw['assegnatario_id'],
      problema.raw['responsabileId'],
    ]);
    if (currentId != null && currentId.isNotEmpty && rawId == currentId) {
      return true;
    }
    final currentName = ApiProvider.client.currentUserName
        ?.trim()
        .toLowerCase();
    final assigneeName = _responsabileNome?.trim().toLowerCase();
    if (currentName != null &&
        currentName.isNotEmpty &&
        assigneeName == currentName) {
      return true;
    }
    return false;
  }

  String? get _responsabileNome {
    final name = _firstString([
      _problema.raw['assegnatarioNome'],
      _problema.raw['assegnatario_nome'],
      _problema.raw['responsabileNome'],
      _problema.raw['responsabile_nome'],
      _problema.raw['assegnatario'],
      _problema.raw['responsabile'],
    ]);
    if (name != null && name.trim().isNotEmpty) return name.trim();
    if (_isCurrentUserAssignee) return ApiProvider.client.currentUserName;
    return null;
  }

  String get _descrizione =>
      _firstString([
        _problema.raw['descrizione'],
        _problema.raw['messaggio'],
      ]) ??
      'Nessuna descrizione disponibile.';

  String get _segnalatoDa =>
      _firstString([
        _problema.raw['segnalatoDa'],
        _problema.raw['autore'],
        _problema.raw['createdByName'],
      ]) ??
      'Coinquilino';

  String get _segnalatoOre =>
      _problema.raw['segnalatoOre']?.toString() ?? '09:15';

  String get _segnalatoData =>
      _problema.raw['segnalatoData']?.toString() ?? '18 apr';

  List<_HistoryEvent> get _storicoStati {
    final events = <_HistoryEvent>[];
    final raw = _problema.raw;

    // Evento segnalazione
    final segnalatoDaInitials = _initials(_segnalatoDa);
    events.add(
      _HistoryEvent(
        label: 'Segnalato',
        color: AppColors.statusNegative,
        timestamp: '$_segnalatoData - $_segnalatoOre - $segnalatoDaInitials',
      ),
    );

    // Evento assegnazione (se presente)
    if (!_isSegnalato) {
      final assegnatoOre = raw['assegnatoOre']?.toString() ?? '11:32';
      final assegnatoData = raw['assegnatoData']?.toString() ?? '18 apr';
      final assigneeNote =
          raw['assegnatoNota']?.toString() ??
          '${_initials(_responsabileNome ?? 'FP')} ha accettato';
      events.add(
        _HistoryEvent(
          label: 'Assegnato',
          color: AppColors.problemPriorityMedium,
          timestamp: '$assegnatoData - $assegnatoOre - $assigneeNote',
        ),
      );
    }

    return events;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _handleAssignMe() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
      final updated = await ApiProvider.problemi.autoAssegna(
        casaId,
        _problema.id,
      );
      if (!mounted) return;
      setState(() {
        _problema = updated;
        _priorityOverride = updated.priorita;
        _isProcessing = false;
      });
      Navigator.of(context).pushReplacementNamed('/problemi');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ti sei preso in carico il problema!')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile assegnare il problema.')),
      );
    }
  }

  Future<void> _handleDeassign() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
      await ApiProvider.problemi.rinuncia(casaId, _problema.id);
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(
          context,
        ).pushReplacementNamed(DeassegnazioneSuccessoScreen.routeName);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile deassegnare il problema.')),
        );
      }
    }
  }

  Future<void> _handleElimina() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
      await ApiProvider.problemi.delete(casaId, _problema.id);
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pushReplacementNamed('/problemi');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile eliminare il problema.')),
        );
      }
    }
  }

  Future<void> _handleRisolto() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
      await ApiProvider.problemi.aggiornaStato(casaId, _problema.id, {
        'stato': 'Risolto',
      });
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pushReplacementNamed('/problemi');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile risolvere il problema.')),
        );
      }
    }
  }

  Future<void> _handlePriorita(String priorita) async {
    if (_isProcessing || priorita == _normalizedPriority) return;
    setState(() => _isProcessing = true);
    try {
      final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
      final updated = await ApiProvider.problemi.aggiornaPriorita(
        casaId,
        _problema.id,
        {'priorita': priorita},
      );
      if (!mounted) return;
      setState(() {
        _problema = updated;
        _priorityOverride = updated.priorita;
        _isProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aggiornare la priorità.')),
      );
    }
  }

  void _showConfirmDialog({
    required String title,
    required String body,
    required Color accentColor,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chiudi',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, a1, a2) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C192E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: accentColor,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  body,
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Annulla',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isCreator {
    if (ActiveCasaScope.read(context).isHomeAdmin) return true;
    final currentId = ApiProvider.client.currentUserId?.trim();
    final rawCreatorId = _firstString([
      _problema.raw['creatoreId'],
      _problema.raw['autoreId'],
      _problema.raw['segnalatoDaId'],
      _problema.raw['createdBy'],
    ]);
    if (currentId != null &&
        currentId.isNotEmpty &&
        rawCreatorId == currentId) {
      return true;
    }
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canDelete = ActiveCasaScope.of(context).isHomeAdmin;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/problemi'),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.p20,
                    AppSizes.p4,
                    AppSizes.p20,
                    AppSizes.p8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitleRow(),
                      const SizedBox(height: AppSizes.p20),
                      // Priorità e azione contestuale in cima
                      _buildPrioritaSection(),
                      const SizedBox(height: AppSizes.p16),
                      _buildContextualActionButton(),
                      const SizedBox(height: AppSizes.p24),
                      // Cards informative
                      if (!_isSegnalato && _responsabileNome != null) ...[
                        _buildResponsabileCard(),
                        const SizedBox(height: AppSizes.p14),
                      ],
                      _buildDescrizioneCard(),
                      const SizedBox(height: AppSizes.p14),
                      if (_isSegnalato) ...[
                        _buildSegnalatoInfoCard(),
                        const SizedBox(height: AppSizes.p14),
                      ],
                      _buildStoricoCard(),
                      const SizedBox(height: AppSizes.p8),
                    ],
                  ),
                ),
              ),
              // Barra azioni fissa in fondo
              DetailActionsBar(
                modifyLabel: 'Modifica problema',
                deleteLabel: 'Elimina problema',
                backLabel: 'Torna ai problemi',
                isCreator: _isCreator,
                onModify: () async {
                  final updated = await Navigator.of(context).pushNamed(
                    ModificaProblemaScreen.routeName,
                    arguments: _problema,
                  );
                  if (updated is Problema && mounted) {
                    setState(() {
                      _problema = updated;
                      _priorityOverride = updated.priorita;
                    });
                  }
                },
                onDelete: canDelete
                    ? () => _showConfirmDialog(
                        title: 'Elimina problema',
                        body:
                            '"${_problema.titolo}" verrà rimosso definitivamente. Tutti i coinquilini verranno avvisati.',
                        accentColor: const Color(0xFFFF3B44),
                        confirmLabel: 'Elimina',
                        onConfirm: _handleElimina,
                      )
                    : null,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header with back nav ──────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p8,
        AppSizes.p16,
        AppSizes.p20,
        AppSizes.p8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.brandAccent,
            iconSize: 20,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            'Problemi',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.brandAccent,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Title + chips row ─────────────────────────────────────────────────────

  Widget _buildTitleRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _problema.titolo,
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.textOnDark,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSizes.p10),
        Row(
          children: [
            _StatoChip(stato: _problema.stato),
            const SizedBox(width: AppSizes.p8),
            _PriorityChip(label: _normalizedPriority),
          ],
        ),
      ],
    );
  }

  // ── Responsabile card ─────────────────────────────────────────────────────

  Widget _buildResponsabileCard() {
    final nome = _responsabileNome ?? 'Coinquilino';
    final label = _isCurrentUserAssignee ? 'Responsabile (tu)' : 'Responsabile';
    return _InfoCard(
      title: label,
      child: Row(
        children: [
          _AvatarCircle(name: nome),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              nome,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.textMutedLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Descrizione card ──────────────────────────────────────────────────────

  Widget _buildDescrizioneCard() {
    return _InfoCard(
      title: 'Descrizione problema',
      child: Text(
        _descrizione,
        style: AppTextStyles.bodyMutedRelaxed.copyWith(
          color: AppColors.textMutedLight,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  // ── Segnalato da card (solo stato segnalato) ──────────────────────────────

  Widget _buildSegnalatoInfoCard() {
    return _InfoCard(
      title: 'Segnalato da',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarCircle(name: _segnalatoDa),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _segnalatoDa,
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.textMutedLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_segnalatoData - $_segnalatoOre',
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: AppColors.textMutedDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Storico stati card ────────────────────────────────────────────────────

  Widget _buildStoricoCard() {
    final events = _storicoStati;
    return _InfoCard(
      title: 'Storico stato',
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            _HistoryRow(event: events[i]),
            if (i < events.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 4.5),
                      color: AppColors.dividerOnDark,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Modifica priorità ─────────────────────────────────────────────────────

  Widget _buildPrioritaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modifica Priorità',
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.brandAccent,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        Row(
          children: [
            _PriorityButton(
              label: 'Urgente',
              dotColor: AppColors.problemPriorityUrgent,
              bgColor: const Color(0xFF710002),
              isSelected: _normalizedPriority == 'Urgente',
              onTap: () => _handlePriorita('Urgente'),
            ),
            const SizedBox(width: AppSizes.p8),
            _PriorityButton(
              label: 'Media',
              dotColor: AppColors.problemPriorityMedium,
              bgColor: const Color(0xFF7E3B00),
              isSelected: _normalizedPriority == 'Media',
              onTap: () => _handlePriorita('Media'),
            ),
            const SizedBox(width: AppSizes.p8),
            _PriorityButton(
              label: 'Bassa',
              dotColor: AppColors.problemPriorityLow,
              bgColor: const Color(0xFF786000),
              isSelected: _normalizedPriority == 'Bassa',
              onTap: () => _handlePriorita('Bassa'),
            ),
          ],
        ),
      ],
    );
  }

  // ── Azione contestuale (stato-dipendente) ─────────────────────────────────

  Widget _buildContextualActionButton() {
    if (_isSegnalato) {
      return _ActionButton(
        label: 'Assegna a me',
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        isLoading: _isProcessing,
        onPressed: _handleAssignMe,
      );
    }

    if (_isCurrentUserAssignee) {
      return Column(
        children: [
          _ActionButton(
            label: 'Segna come risolto',
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            isLoading: false,
            onPressed: _isProcessing
                ? () {}
                : () => _showConfirmDialog(
                    title: 'Segna come risolto',
                    body:
                        'Confermi che il problema è stato risolto? Tutti i coinquilini verranno avvisati.',
                    accentColor: const Color(0xFF4CAF50),
                    confirmLabel: 'Conferma',
                    onConfirm: _handleRisolto,
                  ),
          ),
          const SizedBox(height: AppSizes.p10),
          _ActionButton(
            label: 'Rinuncia al problema',
            color: const Color(0xFFBE2C2C),
            isLoading: _isProcessing,
            onPressed: () => _showConfirmDialog(
              title: 'De-assegnazione',
              body:
                  'Se rinunci al problema, tornerà allo stato Segnalato e tutti i coinquilini verranno avvisati.',
              accentColor: AppColors.warning,
              confirmLabel: 'Conferma',
              onConfirm: _handleDeassign,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.brandAccent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p10),
          child,
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length == 1
        ? parts[0][0].toUpperCase()
        : (parts[0][0] + parts[1][0]).toUpperCase();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF304A7E),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandAccent, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF85A7F0),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatoChip extends StatelessWidget {
  const _StatoChip({required this.stato});
  final String stato;

  @override
  Widget build(BuildContext context) {
    final lower = stato.toLowerCase();
    final Color bg;
    final Color fg;
    final String label;

    if (lower.contains('assegn')) {
      bg = AppColors.warning.withValues(alpha: 0.22);
      fg = AppColors.warning;
      label = 'Assegnato';
    } else if (lower.contains('risolt')) {
      bg = AppColors.statusPositive.withValues(alpha: 0.22);
      fg = AppColors.statusPositive;
      label = 'Risolto';
    } else {
      bg = AppColors.statusPositive.withValues(alpha: 0.18);
      fg = AppColors.statusPositive;
      label = 'Segnalato';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    switch (label.toLowerCase()) {
      case 'urgente':
        bg = const Color(0xFF6B1B1B);
        fg = AppColors.problemPriorityUrgent;
      case 'media':
        bg = const Color(0xFF7B4508);
        fg = AppColors.problemPriorityMedium;
      default:
        bg = const Color(0xFF806600);
        fg = AppColors.problemPriorityLow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        border: Border.all(color: fg.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.event});
  final _HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: event.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.label,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: 15,
                ),
              ),
              Text(
                event.timestamp,
                style: AppTextStyles.bodyMuted.copyWith(
                  color: AppColors.textMutedDark,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.label,
    required this.dotColor,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final Color dotColor;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(bgColor, Colors.white, 0.28)!,
        bgColor,
        Color.lerp(bgColor, Colors.black, 0.18)!,
      ],
      stops: const [0, 0.62, 1],
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 50,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandAccent
                  : AppColors.darkBackground,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.4)
                    : AppColors.shadowStrong,
                blurRadius: isSelected ? 8 : 4,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: dotColor, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.gradient,
    this.color,
    required this.isLoading,
    required this.onPressed,
  });
  final String label;
  final Gradient? gradient;
  final Color? color;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(AppSizes.radius16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textOnDark,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textOnDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryEvent {
  const _HistoryEvent({
    required this.label,
    required this.color,
    required this.timestamp,
  });
  final String label;
  final Color color;
  final String timestamp;
}
