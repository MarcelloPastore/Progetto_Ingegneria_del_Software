import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/state/active_casa_session.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/delete_confirm_dialog.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/turni/screens/assegna_a_me.dart';
import 'package:coincasa_app/features/turni/screens/turno_create_screen.dart';

String _assigneeDisplayName(Inquilino inquilino) {
  final username = inquilino.username.trim();
  if (username.isNotEmpty) return username;
  final email = inquilino.email.trim();
  if (email.isNotEmpty) return email.split('@').first;
  return 'coinquilino';
}

bool _matchesCurrentUser(Inquilino inquilino) {
  final currentId = ApiProvider.client.currentUserId?.trim();
  if (currentId != null && currentId.isNotEmpty) {
    if (inquilino.id.trim() == currentId) {
      return true;
    }
  }

  final email = ApiProvider.client.currentUserEmail?.trim().toLowerCase();
  final name = ApiProvider.client.currentUserName?.trim().toLowerCase();
  final normalizedValues = <String>{
    if (email != null && email.isNotEmpty) inquilino.email.trim().toLowerCase(),
    if (name != null && name.isNotEmpty)
      inquilino.nomeCompleto.trim().toLowerCase(),
    if (name != null && name.isNotEmpty) inquilino.nome.trim().toLowerCase(),
    if (name != null && name.isNotEmpty)
      inquilino.username.trim().toLowerCase(),
  };

  return normalizedValues.contains(email) || normalizedValues.contains(name);
}

List<Inquilino> _validAssignees(List<Inquilino> inquilini) {
  return inquilini.where((item) => item.id.isNotEmpty).toList(growable: false);
}

List<Inquilino> _otherAssignees(List<Inquilino> assignees) {
  return assignees
      .where((inquilino) => !_matchesCurrentUser(inquilino))
      .toList(growable: false);
}

Inquilino? _findCurrentUser(List<Inquilino> inquilini) {
  for (final inquilino in inquilini) {
    if (_matchesCurrentUser(inquilino)) {
      return inquilino;
    }
  }
  return null;
}

Inquilino? _findInquilinoById(List<Inquilino> inquilini, String? id) {
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final inquilino in inquilini) {
    if (inquilino.id == id) {
      return inquilino;
    }
  }
  return null;
}

String _resolveCreatoreNome(_TurnoDetailData data) {
  final nome = data.turno.creatoreNome.trim();
  if (nome.isNotEmpty) return nome;
  final id = data.turno.creatoreId.trim();
  if (id.isNotEmpty) {
    final inquilino = _findInquilinoById(data.inquilini, id);
    if (inquilino != null) return _assigneeDisplayName(inquilino);
  }
  return '';
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return 'data non disponibile';
  }
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _TurnoDetailData {
  const _TurnoDetailData({
    required this.casaId,
    required this.turno,
    required this.inquilini,
  });

  final String casaId;
  final Turno turno;
  final List<Inquilino> inquilini;
}

class DettaglioTurnoAdminScreen extends ConsumerStatefulWidget {
  const DettaglioTurnoAdminScreen({super.key});

  static const routeName = '/turni/dettaglio-admin';

  @override
  ConsumerState<DettaglioTurnoAdminScreen> createState() =>
      _DettaglioTurnoAdminScreenState();
}

class _DettaglioTurnoAdminScreenState
    extends ConsumerState<DettaglioTurnoAdminScreen> {
  bool _initialized = false;
  late Future<_TurnoDetailData?> _detailFuture;
  bool _isSubmitting = false;
  bool _assigneeMenuOpen = false;
  String? _selectedAssigneeId;

  String? get _turnoId {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is String && args.isNotEmpty ? args : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _detailFuture = _loadDetailData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<_TurnoDetailData?> _loadDetailData() async {
    final turnoId = _turnoId;
    if (turnoId == null) {
      return null;
    }

    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }

    final casa = await ensureActiveCasaContext(
      activeCasaController,
      caseUtente: caseUtente,
    );
    final results = await Future.wait<dynamic>([
      ApiProvider.turni.getById(casa.id, turnoId),
      ApiProvider.casa.listInquilini(casa.id),
    ]);

    return _TurnoDetailData(
      casaId: casa.id,
      turno: results[0] as Turno,
      inquilini: results[1] as List<Inquilino>,
    );
  }

  Future<void> _handleAssignMe(_TurnoDetailData data) async {
    setState(() => _isSubmitting = true);
    try {
      await ApiProvider.turni.autoAssegna(data.casaId, data.turno.id);
      if (mounted) {
        Navigator.of(context).pushNamed(AssegnaAMeSuccessScreen.routeName);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile assegnare il turno.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleAssigneeSelected(
    _TurnoDetailData data,
    String assigneeId,
  ) async {
    setState(() {
      _selectedAssigneeId = assigneeId;
      _assigneeMenuOpen = false;
      _isSubmitting = true;
    });

    try {
      await ApiProvider.turni.assegna(data.casaId, data.turno.id, {
        'idUtente': assigneeId,
      });
      if (mounted) {
        final selectedInquilino = _findInquilinoById(
          data.inquilini,
          assigneeId,
        );
        final nomeInquilino = selectedInquilino != null
            ? _assigneeDisplayName(selectedInquilino)
            : 'coinquilino';
        Navigator.of(context).pushNamed(
          AssegnaAMeSuccessScreen.routeName,
          arguments: nomeInquilino,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossibile aggiornare l'assegnatario."),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final data = await _detailFuture;
    if (!mounted || data == null) return;

    final turno = data.turno;
    await showDeleteConfirmDialog(
      context: context,
      title: 'Eliminare il turno?',
      description:
          '${turno.titolo} verrà rimosso definitivamente. '
          'Le occorrenze future saranno aggiornate.',
      onConfirm: () => ApiProvider.turni.delete(data.casaId, turno.id),
      onSuccess: () {
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacementNamed(TurnoRimossoScreen.routeName);
        }
      },
    );
  }

  String? _defaultAssigneeId(List<Inquilino> assignees) {
    if (_selectedAssigneeId != null &&
        assignees.any((item) => item.id == _selectedAssigneeId)) {
      return _selectedAssigneeId;
    }
    return assignees.isEmpty ? null : assignees.first.id;
  }

  String _selectedAssigneeLabel(List<Inquilino> assignees) {
    final selected = _findInquilinoById(
      assignees,
      _defaultAssigneeId(assignees),
    );
    return selected != null ? _assigneeDisplayName(selected) : 'coinquilino';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TurnoDetailData?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final assignees = data == null
            ? const <Inquilino>[]
            : _otherAssignees(_validAssignees(data.inquilini));
        final selectedAssigneeId = _defaultAssigneeId(assignees);
        final currentUser = data == null
            ? null
            : _findCurrentUser(data.inquilini);
        final isCreator =
            currentUser != null &&
            data != null &&
            data.turno.isCreatedBy(currentUser.id);
        final canEditTurno =
            isCreator || ActiveCasaScope.of(context).isHomeAdmin;

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          bottomNavigationBar: const HouseQuickNav(currentRoute: '/turni'),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brandAccent,
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.p14,
                            AppSizes.p8,
                            AppSizes.p14,
                            AppSizes.p16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DetailHeader(
                                onBack: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(height: AppSizes.p24),
                              _TurnoSummaryCard(turno: data?.turno),
                              const SizedBox(height: AppSizes.p24),
                              _ResponsibleCard(
                                turno: data?.turno,
                                inquilini: data?.inquilini ?? const [],
                              ),
                              if (data != null) ...[
                                const SizedBox(height: AppSizes.p24),
                                _CreatorRow(
                                  creatoreNome: _resolveCreatoreNome(data),
                                  creatoreId: data.turno.creatoreId,
                                ),
                              ],
                              const SizedBox(height: AppSizes.p48),
                              Text(
                                'Vuoi occupartene tu?',
                                style: AppTextStyles.bodyStrong.copyWith(
                                  color: AppColors.textMutedLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSizes.p18),
                              _PrimaryActionButton(
                                label: isLoading
                                    ? 'Caricamento...'
                                    : 'Assegna a me',
                                onPressed:
                                    _isSubmitting ||
                                        data == null ||
                                        (data.turno.assegnatarioId.isNotEmpty &&
                                            data.turno.assegnatarioId ==
                                                ApiProvider
                                                    .client
                                                    .currentUserId)
                                    ? null
                                    : () => _handleAssignMe(data),
                              ),
                              if (assignees.isNotEmpty) ...[
                                const SizedBox(height: AppSizes.p10),
                                _AssigneeSelector(
                                  assignees: assignees,
                                  selectedAssigneeId: selectedAssigneeId,
                                  selectedAssigneeLabel: _selectedAssigneeLabel(
                                    assignees,
                                  ),
                                  expanded: _assigneeMenuOpen,
                                  isSubmitting: _isSubmitting,
                                  onToggle: () {
                                    setState(
                                      () => _assigneeMenuOpen =
                                          !_assigneeMenuOpen,
                                    );
                                  },
                                  onSelected: (value) {
                                    if (data != null) {
                                      _handleAssigneeSelected(data, value);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      DetailActionsBar(
                        modifyLabel: 'Modifica turno',
                        deleteLabel: 'Elimina turno',
                        backLabel: 'Torna ai turni',
                        isCreator: canEditTurno,
                        onModify: _isSubmitting || data == null
                            ? null
                            : () => Navigator.of(context).pushNamed(
                                TurnoCreateScreen.routeName,
                                arguments: data.turno.id,
                              ),
                        onDelete: _isSubmitting ? null : _handleDelete,
                        onBack: () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/turni'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.p40,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.brandAccent,
              size: 28,
            ),
          ),
          Expanded(
            child: Text(
              'Dettaglio turno',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.brandAccent,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.p48),
        ],
      ),
    );
  }
}

class _TurnoSummaryCard extends StatelessWidget {
  const _TurnoSummaryCard({required this.turno});

  final Turno? turno;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p12,
        AppSizes.p8,
        AppSizes.p12,
        AppSizes.p10,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${turno?.titolo ?? 'Turno'}\n',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textOnDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text:
                  '${turno?.frequenzaLabel ?? 'Ogni giorno'}\nprossimo: ${_formatDate(turno?.dataProssimaPulizia)}',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textMutedLight,
                fontSize: 20,
                height: 1.14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsibleCard extends StatelessWidget {
  const _ResponsibleCard({required this.turno, required this.inquilini});

  final Turno? turno;
  final List<Inquilino> inquilini;

  @override
  Widget build(BuildContext context) {
    final current = turno == null
        ? null
        : _findInquilinoById(inquilini, turno!.assegnatarioId);
    final label = current != null
        ? _assigneeDisplayName(current)
        : (turno?.assegnatarioNome.isNotEmpty == true
              ? turno!.assegnatarioNome
              : '?');

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p12,
        AppSizes.p16,
        AppSizes.p12,
        AppSizes.p18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESPONSABILE',
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textMutedLight,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p18),
          Row(
            children: [
              UserAvatar(
                radius: 20,
                userId: current?.id,
                username: current?.username ?? (label == '?' ? null : label),
                fallback: '?',
              ),
              const SizedBox(width: AppSizes.p10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: const Color(0xFF20F545),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (turno?.rotazioneAttiva == true)
                    Text(
                      'Assegnato da rotazione automatica',
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textMutedDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.textOnDark,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonCompact.copyWith(
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AssigneeSelector extends StatefulWidget {
  const _AssigneeSelector({
    required this.assignees,
    required this.selectedAssigneeId,
    required this.selectedAssigneeLabel,
    required this.expanded,
    required this.isSubmitting,
    required this.onToggle,
    required this.onSelected,
  });

  final List<Inquilino> assignees;
  final String? selectedAssigneeId;
  final String selectedAssigneeLabel;
  final bool expanded;
  final bool isSubmitting;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelected;

  @override
  State<_AssigneeSelector> createState() => _AssigneeSelectorState();
}

class _AssigneeSelectorState extends State<_AssigneeSelector> {
  final LayerLink _menuLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _insertScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.expanded) {
      _scheduleInsert();
    }
  }

  @override
  void didUpdateWidget(covariant _AssigneeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && _overlayEntry == null) {
      _scheduleInsert();
    } else if (!widget.expanded && _overlayEntry != null) {
      _hideOverlay();
    } else if (widget.expanded && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.expanded) {
          _overlayEntry?.markNeedsBuild();
        }
      });
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _scheduleInsert() {
    if (_insertScheduled || _overlayEntry != null) {
      return;
    }
    _insertScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertScheduled = false;
      if (mounted && widget.expanded) {
        _showOverlay();
      }
    });
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggle,
                child: Container(
                  color: AppColors.darkBackground.withValues(alpha: 0.28),
                ),
              ),
            ),
            CompositedTransformFollower(
              link: _menuLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: _AssigneeMenu(
                options: widget.assignees,
                selectedId: widget.selectedAssigneeId ?? '',
                onSelected: widget.onSelected,
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assignees.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p27),
      child: CompositedTransformTarget(
        link: _menuLink,
        child: InkWell(
          onTap: widget.isSubmitting ? null : widget.onToggle,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF5A3317),
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              border: Border.all(color: AppColors.lockOrange, width: 1.2),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p12,
              AppSizes.p0,
              AppSizes.p16,
              AppSizes.p0,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFF3E8FF),
                  child: Image(
                    image: AssetImage(
                      'assets/Icons/assegna_a_qualcuno_help.png',
                    ),
                    width: 32,
                    height: 32,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Assegna a ${widget.selectedAssigneeLabel}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.warning,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  widget.expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.warning,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssigneeMenu extends StatelessWidget {
  const _AssigneeMenu({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Inquilino> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: const Color(0xFF65401E),
          borderRadius: BorderRadius.circular(AppSizes.radius5),
          border: Border.all(color: AppColors.lockOrange, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: AppSizes.p6,
              offset: Offset(0, AppSizes.p4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (option) => InkWell(
                  onTap: () => onSelected(option.id),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p10,
                    ),
                    decoration: option.id == selectedId
                        ? const BoxDecoration(color: Color(0x885A3317))
                        : null,
                    child: Text(
                      _assigneeDisplayName(option),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.warning,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.creatoreNome, this.creatoreId = ''});

  final String creatoreNome;
  final String creatoreId;

  @override
  Widget build(BuildContext context) {
    final nome = creatoreNome.trim();
    final seed = creatoreId.isNotEmpty ? creatoreId : nome;
    final initials = nome.isNotEmpty ? initialsFromText(nome) : 'C';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: userAvatarColorsForSeed(seed).background,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p10),
        Text(
          '${nome.isNotEmpty ? nome : 'Coinquilino'} ha creato questo turno',
          style: const TextStyle(
            color: Color(0xFFAFAEAE),
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class TurnoRimossoScreen extends StatelessWidget {
  const TurnoRimossoScreen({super.key});

  static const routeName = '/turni/rimosso';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p24,
            AppSizes.p90,
            AppSizes.p24,
            AppSizes.p90,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: AppColors.errorStrong,
                size: 92,
              ),
              const SizedBox(height: AppSizes.p58),
              Text(
                'Turno rimosso',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSizes.p28),
              Text(
                'Il turno e stato eliminato\n'
                'correttamente. Le ricorrenze future\n'
                'sono state aggiornate',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: 20,
                  height: 1.16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width:
                    double.infinity, // Adapted from 340, keeping it responsive
                height: 53.28, // As per requested style
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(AppColors.brandPrimary, Colors.white, 0.30)!,
                      AppColors.brandPrimary,
                      Color.lerp(AppColors.brandPrimary, Colors.black, 0.18)!,
                    ],
                    stops: const [0, 0.62, 1],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      15,
                    ), // As per requested style
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x005228AD),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/turni'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors
                        .transparent, // Make button background transparent to show gradient
                    foregroundColor:
                        Colors.transparent, // Text color handled by Text widget
                    side: BorderSide.none, // Remove button border
                    padding: EdgeInsets
                        .zero, // Padding handled by the outer Container's height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        15,
                      ), // Match outer container's border radius
                    ),
                    elevation: 0, // Remove default button elevation
                    shadowColor:
                        Colors.transparent, // Remove default button shadow
                  ),
                  child: const Text(
                    // Use const for performance
                    'Torna ai turni',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // As per requested style
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: const Color(0xFF3E3964),
    borderRadius: BorderRadius.circular(AppSizes.radius8),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadowStrong,
        blurRadius: AppSizes.p6,
        offset: Offset(0, AppSizes.p4),
      ),
    ],
  );
}
