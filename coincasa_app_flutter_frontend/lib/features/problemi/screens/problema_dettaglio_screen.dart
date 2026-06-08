import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';

class ProblemaDettaglioScreen extends StatefulWidget {
  const ProblemaDettaglioScreen({super.key});

  static const String routeName = '/problemi/dettaglio';

  @override
  State<ProblemaDettaglioScreen> createState() =>
      _ProblemaDettaglioScreenState();
}

class _ProblemaDettaglioScreenState extends State<ProblemaDettaglioScreen> {
  final LayerLink _priorityMenuLink = LayerLink();

  OverlayEntry? _priorityOverlay;
  bool _initialized = false;
  bool _menuScheduled = false;
  Problema? _problema;
  String? _priorityOverride;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _problema = _resolveProblema(ModalRoute.of(context)?.settings.arguments);
    _priorityOverride = _problema?.priorita;
  }

  @override
  void dispose() {
    _hidePriorityMenu();
    super.dispose();
  }

  Problema? _resolveProblema(dynamic args) {
    if (args is Problema) {
      return args;
    }
    if (args is Map<String, dynamic>) {
      return Problema.fromJson(args);
    }
    if (args is Map) {
      return Problema.fromJson(Map<String, dynamic>.from(args));
    }
    return null;
  }

  String get _priorityLabel {
    final value = (_priorityOverride ?? _problema?.priorita ?? 'Media').trim();
    final lower = value.toLowerCase();
    if (lower.contains('urg')) return 'Urgente';
    if (lower.contains('med')) return 'Media';
    if (lower.contains('bass')) return 'Bassa';
    return value.isEmpty ? 'Media' : value;
  }

  bool get _isCurrentUserAssignee {
    final problema = _problema;
    if (problema == null) return false;

    final currentId = ApiProvider.client.currentUserId?.trim();
    final rawAssigneeId = _firstString([
      problema.raw['assegnatarioId'],
      problema.raw['assegnatario_id'],
      problema.raw['idAssegnatario'],
      problema.raw['responsabileId'],
      problema.raw['responsabile_id'],
    ]);
    if (currentId != null &&
        currentId.isNotEmpty &&
        rawAssigneeId != null &&
        rawAssigneeId == currentId) {
      return true;
    }

    final currentEmail = ApiProvider.client.currentUserEmail
        ?.trim()
        .toLowerCase();
    final currentName = ApiProvider.client.currentUserName
        ?.trim()
        .toLowerCase();
    final assigneeName = _rawResponsabileNome(problema)?.trim().toLowerCase();

    return (currentEmail != null &&
            currentEmail.isNotEmpty &&
            _firstString([
                  problema.raw['assegnatarioEmail'],
                  problema.raw['assegnatario_email'],
                  problema.raw['responsabileEmail'],
                  problema.raw['responsabile_email'],
                ])?.trim().toLowerCase() ==
                currentEmail) ||
        (currentName != null &&
            currentName.isNotEmpty &&
            assigneeName != null &&
            assigneeName == currentName);
  }

  String _responsabileDisplayLabel() {
    return _isCurrentUserAssignee ? 'Responsabile (tu)' : 'Responsabile';
  }

  String? _responsabileNome(Problema problema) {
    final name = _rawResponsabileNome(problema);
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    final currentName = ApiProvider.client.currentUserName?.trim();
    if (_isCurrentUserAssignee &&
        currentName != null &&
        currentName.isNotEmpty) {
      return currentName;
    }
    return null;
  }

  String? _rawResponsabileNome(Problema problema) {
    final name = _firstString([
      problema.raw['assegnatarioNome'],
      problema.raw['assegnatario_nome'],
      problema.raw['responsabileNome'],
      problema.raw['responsabile_nome'],
      problema.raw['assegnatario'],
      problema.raw['responsabile'],
    ]);
    return name;
  }

  List<_StatusEvent> _historyEvents(Problema problema) {
    final events = <_StatusEvent>[];

    final reportedAt = _extractDate([
      problema.raw['dataSegnalazione'],
      problema.raw['createdAt'],
      problema.raw['created_at'],
      problema.raw['segnalatoIl'],
      problema.raw['segnalato_il'],
    ]);
    events.add(
      _StatusEvent(
        label: 'Segnalato',
        detail: _formatHistoryDetail(
          reportedAt,
          actor: _firstString([
            problema.raw['segnalatoDa'],
            problema.raw['segnalato_da'],
            problema.raw['createdBy'],
            problema.raw['autore'],
          ]),
          fallback: 'Segnalazione registrata',
        ),
        color: AppColors.statusNegative,
      ),
    );

    final assignedAt = _extractDate([
      problema.raw['dataAssegnazione'],
      problema.raw['assignedAt'],
      problema.raw['assigned_at'],
      problema.raw['assegnatoIl'],
      problema.raw['assegnato_il'],
    ]);
    events.add(
      _StatusEvent(
        label: 'Assegnato',
        detail: _formatHistoryDetail(
          assignedAt,
          actor: _firstString([
            problema.raw['assegnatoDa'],
            problema.raw['assegnato_da'],
            problema.raw['responsabileNome'],
            problema.raw['responsabile_nome'],
            problema.raw['assegnatarioNome'],
            problema.raw['assegnatario_nome'],
          ]),
          fallback: 'Assegnazione completata',
        ),
        color: AppColors.problemPriorityMedium,
      ),
    );

    final statusHistory =
        _parseExplicitHistory(problema.raw['storico']) ??
        _parseExplicitHistory(problema.raw['history']) ??
        _parseExplicitHistory(problema.raw['storia']);
    if (statusHistory != null && statusHistory.isNotEmpty) {
      return statusHistory;
    }

    return events;
  }

  List<_StatusEvent>? _parseExplicitHistory(dynamic value) {
    if (value is! List) return null;

    final events = <_StatusEvent>[];
    for (final item in value) {
      if (item is! Map) continue;
      final raw = Map<String, dynamic>.from(item);
      final label =
          _firstString([
            raw['stato'],
            raw['label'],
            raw['titolo'],
            raw['name'],
          ]) ??
          'Evento';
      final detail =
          _firstString([
            raw['dettaglio'],
            raw['detail'],
            raw['descrizione'],
            raw['note'],
          ]) ??
          '';
      final date = _extractDate([
        raw['data'],
        raw['date'],
        raw['createdAt'],
        raw['created_at'],
        raw['timestamp'],
      ]);
      events.add(
        _StatusEvent(
          label: label,
          detail: detail.isNotEmpty
              ? detail
              : _formatHistoryDetail(date, fallback: 'Aggiornamento stato'),
          color: _statusColor(label),
        ),
      );
    }
    return events;
  }

  Color _statusColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('assegn')) return AppColors.problemPriorityMedium;
    if (lower.contains('risolt') || lower.contains('chius')) {
      return AppColors.statusSuccess;
    }
    if (lower.contains('segna') || lower.contains('report')) {
      return AppColors.statusNegative;
    }
    return AppColors.statusInfo;
  }

  DateTime? _extractDate(List<dynamic> candidates) {
    for (final candidate in candidates) {
      if (candidate is DateTime) {
        return candidate;
      }
      if (candidate is String && candidate.trim().isNotEmpty) {
        return DateTime.tryParse(candidate);
      }
    }
    return null;
  }

  String _formatHistoryDetail(
    DateTime? date, {
    String? actor,
    required String fallback,
  }) {
    final datePart = date == null ? fallback : _formatDate(date);
    final actorPart = _actorInitials(actor);
    if (actorPart == null || actorPart.isEmpty) {
      return datePart;
    }
    return '$datePart - $actorPart';
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'gen',
      'feb',
      'mar',
      'apr',
      'mag',
      'giu',
      'lug',
      'ago',
      'set',
      'ott',
      'nov',
      'dic',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = monthNames[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month - $hour:$minute';
  }

  String? _actorInitials(String? name) {
    if (name == null) return null;
    final clean = name.trim();
    if (clean.isEmpty) return null;
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  void _togglePriorityMenu() {
    if (_priorityOverlay != null) {
      _hidePriorityMenu();
    } else {
      _showPriorityMenu();
    }
  }

  void _showPriorityMenu() {
    if (_priorityOverlay != null || _menuScheduled) {
      return;
    }

    _menuScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _menuScheduled = false;
      if (!mounted || _priorityOverlay != null) {
        return;
      }

      _priorityOverlay = OverlayEntry(
        builder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _hidePriorityMenu,
                  child: Container(
                    color: AppColors.darkBackground.withValues(alpha: 0.24),
                  ),
                ),
              ),
              CompositedTransformFollower(
                link: _priorityMenuLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 6),
                child: _PriorityMenu(
                  onSelected: (value) {
                    setState(() => _priorityOverride = value);
                    _hidePriorityMenu();
                  },
                ),
              ),
            ],
          );
        },
      );

      Overlay.of(context, rootOverlay: true).insert(_priorityOverlay!);
    });
  }

  void _hidePriorityMenu() {
    _priorityOverlay?.remove();
    _priorityOverlay = null;
  }

  void _showStubAction(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final problema = _problema;
    if (problema == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Center(
            child: Text(
              'Problema non disponibile',
              style: AppTextStyles.bodyStrong,
            ),
          ),
        ),
      );
    }

    final assigneeName = _responsabileNome(problema) ?? 'Francesco';
    final historyEvents = _historyEvents(problema);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/problemi'),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hidePriorityMenu,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p8,
                AppSizes.p16,
                AppSizes.p20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailHeader(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: AppSizes.p12),
                  Text(
                    problema.titolo,
                    style: AppTextStyles.screenTitleStrong.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Row(
                    children: [
                      _StatusPill(
                        label: 'Assegnato',
                        background: AppColors.warning.withValues(alpha: 0.22),
                        foreground: AppColors.warning,
                      ),
                      const SizedBox(width: AppSizes.p8),
                      CompositedTransformTarget(
                        link: _priorityMenuLink,
                        child: InkWell(
                          onTap: _togglePriorityMenu,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius16,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.p12,
                              vertical: AppSizes.p6,
                            ),
                            decoration: BoxDecoration(
                              color: _priorityBackground(_priorityLabel),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius16,
                              ),
                              border: Border.all(
                                color: _priorityForeground(
                                  _priorityLabel,
                                ).withValues(alpha: 0.55),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _priorityLabel,
                                  style: TextStyle(
                                    color: _priorityForeground(_priorityLabel),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.p2),
                                Icon(
                                  _priorityOverlay == null
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: _priorityForeground(_priorityLabel),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p20),
                  _DetailCard(
                    title: _responsabileDisplayLabel(),
                    child: Row(
                      children: [
                        _AssigneeAvatar(name: assigneeName),
                        const SizedBox(width: AppSizes.p12),
                        Expanded(
                          child: Text(
                            assigneeName,
                            style: AppTextStyles.screenTitleStrong.copyWith(
                              color: AppColors.textMutedLight,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p20),
                  _DetailCard(
                    title: 'Descrizione problema',
                    child: Text(
                      _resolveDescription(problema),
                      style: AppTextStyles.bodyMutedRelaxed.copyWith(
                        color: AppColors.textMutedLight,
                        fontSize: 18,
                        height: 1.28,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p20),
                  _DetailCard(
                    title: 'Storico stato',
                    child: Column(
                      children: [
                        for (var i = 0; i < historyEvents.length; i++) ...[
                          _StatusHistoryRow(event: historyEvents[i]),
                          if (i != historyEvents.length - 1)
                            const SizedBox(height: AppSizes.p14),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p20),
                  _DangerActionButton(
                    label: 'Rinuncia al problema',
                    color: const Color(0xFFBE2C2C),
                    shadowColor: const Color(0xFFBE2C2C),
                    onPressed: () => _showStubAction(
                      'Rinuncia al problema ancora non collegata.',
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  _DangerActionButton(
                    label: 'Segna come risolto',
                    color: const Color(0xFF3F961A),
                    shadowColor: const Color(0xFF3F961A),
                    onPressed: () => _showStubAction(
                      'Marcatura come risolto ancora non collegata.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resolveDescription(Problema problema) {
    final description = _firstString([
      problema.raw['descrizione'],
      problema.raw['description'],
      problema.raw['dettaglio'],
      problema.raw['note'],
      problema.raw['messaggio'],
    ]);
    if (description != null) {
      return description;
    }
    return 'Nessuna descrizione disponibile per questo problema.';
  }

  Color _priorityBackground(String label) {
    switch (label.toLowerCase()) {
      case 'urgente':
        return const Color(0xFF6B1B1B);
      case 'media':
        return const Color(0xFF7B4508);
      case 'bassa':
        return const Color(0xFF806600);
      default:
        return const Color(0xFF6B1B1B);
    }
  }

  Color _priorityForeground(String label) {
    switch (label.toLowerCase()) {
      case 'urgente':
        return AppColors.problemPriorityUrgent;
      case 'media':
        return AppColors.problemPriorityMedium;
      case 'bassa':
        return AppColors.problemPriorityLow;
      default:
        return AppColors.problemPriorityUrgent;
    }
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.brandAccent,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSizes.p4),
        Text(
          'Problemi',
          style: AppTextStyles.backHeader.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p14,
        AppSizes.p12,
        AppSizes.p14,
        AppSizes.p16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.brandAccent,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          child,
        ],
      ),
    );
  }
}

class _AssigneeAvatar extends StatelessWidget {
  const _AssigneeAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF304A7E),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.brandAccent.withValues(alpha: 0.8),
          width: 1.4,
        ),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: Color(0xFF85A7F0),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

class _StatusHistoryRow extends StatelessWidget {
  const _StatusHistoryRow({required this.event});

  final _StatusEvent event;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 14,
            height: 14,
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
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSizes.p3),
              Text(
                event.detail,
                style: AppTextStyles.bodyMuted.copyWith(
                  color: AppColors.textMutedDark,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color shadowColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.36),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: AppColors.textOnDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: AppTextStyles.buttonCompact.copyWith(
              color: AppColors.textOnDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityMenu extends StatelessWidget {
  const _PriorityMenu({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF6E3C0A),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(
            color: AppColors.brandAccent.withValues(alpha: 0.7),
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p8,
              offset: Offset(0, AppSizes.p4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PriorityMenuItem(
              label: 'Media',
              background: const LinearGradient(
                colors: [Color(0xFFCD700A), Color(0xFF964F09)],
              ),
              foreground: AppColors.problemPriorityMedium,
              onTap: () => onSelected('Media'),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFF8A6118)),
            _PriorityMenuItem(
              label: 'Bassa',
              background: const LinearGradient(
                colors: [Color(0xFFB18B07), Color(0xFF7E6500)],
              ),
              foreground: AppColors.problemPriorityLow,
              onTap: () => onSelected('Bassa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityMenuItem extends StatelessWidget {
  const _PriorityMenuItem({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Gradient background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          gradient: background,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _StatusEvent {
  const _StatusEvent({
    required this.label,
    required this.detail,
    required this.color,
  });

  final String label;
  final String detail;
  final Color color;
}
