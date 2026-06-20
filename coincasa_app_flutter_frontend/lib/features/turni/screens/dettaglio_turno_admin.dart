import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/core/widgets/common/delete_confirm_dialog.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/main_cta_button.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/turni/screens/assegna_a_me.dart';
import 'package:coincasa_app/features/turni/screens/turno_create_screen.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/domain/viewmodel/turni_viewmodel.dart';

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

  ({Turno turno, String casaId})? get _navArgs {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final turno = args['turno'];
      final casaId = args['casaId'];
      if (turno is Turno && casaId is String && casaId.isNotEmpty) {
        return (turno: turno, casaId: casaId);
      }
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _detailFuture = _loadDetailData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<_TurnoDetailData?> _loadDetailData() async {
    final nav = _navArgs;
    if (nav == null) return null;

    final state = await ref.read(turniViewModelProvider(nav.casaId).future);
    final turno = await ref
        .read(turniViewModelProvider(nav.casaId).notifier)
        .getTurnoById(nav.turno.id);
    return _TurnoDetailData(
      casaId: nav.casaId,
      turno: turno,
      inquilini: state.inquilini,
    );
  }

  Future<void> _handleAssignMe(_TurnoDetailData data) async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(turniViewModelProvider(data.casaId).notifier)
          .autoAssegnaTurno(data.turno.id);
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
      await ref.read(turniViewModelProvider(data.casaId).notifier).assegnaTurno(
        data.turno.id,
        {'idUtente': assigneeId},
      );
      if (mounted) {
        final selectedInquilino = inquilinoById(data.inquilini, assigneeId);
        final nomeInquilino = selectedInquilino != null
            ? assigneeDisplayName(selectedInquilino)
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
      onConfirm: () => ref
          .read(turniViewModelProvider(data.casaId).notifier)
          .deleteTurno(turno.id),
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
    final selected = inquilinoById(assignees, _defaultAssigneeId(assignees));
    return selected != null ? assigneeDisplayName(selected) : 'coinquilino';
  }

  @override
  Widget build(BuildContext context) {
    final authIdentity = ref.watch(authViewModelProvider).valueOrNull;
    return FutureBuilder<_TurnoDetailData?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: Text(
                    'Impossibile caricare il turno.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMutedLight,
                      fontSize: AppSizes.p16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        final data = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final assignees = data == null
            ? const <Inquilino>[]
            : otherAssignees(validAssignees(data.inquilini), authIdentity);
        final selectedAssigneeId = _defaultAssigneeId(assignees);
        final currentAssignee = data == null
            ? null
            : currentInquilino(data.inquilini, authIdentity);
        final isCreator =
            currentAssignee != null &&
            data != null &&
            data.turno.isCreatedBy(currentAssignee.id);
        final isAdmin = ActiveCasaScope.of(context).isHomeAdmin;
        final canDeleteTurno = isCreator || isAdmin;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                                  creatoreNome: resolveTurnoCreatorName(
                                    data.turno,
                                    data.inquilini,
                                  ),
                                  creatoreId: data.turno.creatoreId,
                                ),
                              ],
                              const SizedBox(height: AppSizes.p48),
                              Text(
                                'Vuoi occupartene tu?',
                                style: AppTextStyles.bodyStrong.copyWith(
                                  color: AppColors.textMutedLight,
                                  fontSize: AppSizes.p18,
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
                                                authIdentity?.id)
                                    ? null
                                    : () => _handleAssignMe(data),
                              ),
                              if (isAdmin && assignees.isNotEmpty) ...[
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
                        isCreator: isCreator,
                        canDelete: canDeleteTurno,
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
              size: AppSizes.p28,
            ),
          ),
          Expanded(
            child: Text(
              'Dettaglio turno',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: AppColors.brandAccent,
                fontSize: AppSizes.p24,
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
                fontSize: AppSizes.p20,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text:
                  '${turno?.frequenzaLabel ?? 'Ogni giorno'}\nprossimo: ${_formatDate(turno?.dataProssimaPulizia)}',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textMutedLight,
                fontSize: AppSizes.p20,
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
        : inquilinoById(inquilini, turno!.assegnatarioId);
    final label = current != null
        ? assigneeDisplayName(current)
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
              fontSize: AppSizes.p15,
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
                      color: AppColors.statusPositive,
                      fontSize: AppSizes.p17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (turno?.rotazioneAttiva == true)
                    Text(
                      'Assegnato da rotazione automatica',
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textMutedDark,
                        fontSize: AppSizes.p14,
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
            borderRadius: BorderRadius.circular(AppSizes.radius13),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonCompact.copyWith(
            fontSize: AppSizes.p23,
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
            height: AppSizes.p44,
            decoration: BoxDecoration(
              color: AppColors.turniAssigneeMenuSurface,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              border: Border.all(
                color: AppColors.lockOrange,
                width: AppSizes.p1_2,
              ),
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
                  backgroundColor: AppColors.surfaceTint,
                  child: Image(
                    image: AssetImage(
                      'assets/Icons/assegna_a_qualcuno_help.png',
                    ),
                    width: AppSizes.p32,
                    height: AppSizes.p32,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Assegna a ${widget.selectedAssigneeLabel}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.warning,
                      fontSize: AppSizes.p16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  widget.expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.warning,
                  size: AppSizes.p25,
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
        width: AppSizes.p170,
        decoration: BoxDecoration(
          color: AppColors.turniAssigneeMenuSurface,
          borderRadius: BorderRadius.circular(AppSizes.radius5),
          border: Border.all(color: AppColors.lockOrange, width: AppSizes.p1),
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
                    height: AppSizes.p44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p10,
                    ),
                    decoration: option.id == selectedId
                        ? const BoxDecoration(
                            color: AppColors.turniAssigneeMenuSurface,
                          )
                        : null,
                    child: Text(
                      assigneeDisplayName(option),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.warning,
                        fontSize: AppSizes.p16,
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
          width: AppSizes.p40,
          height: AppSizes.p40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: userAvatarColorsForSeed(seed).background,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p10),
        Expanded(
          child: Text(
            '${nome.isNotEmpty ? nome : 'Coinquilino'} ha creato questo turno',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: AppSizes.p15,
              fontWeight: FontWeight.w500,
            ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                size: AppSizes.p92,
              ),
              const SizedBox(height: AppSizes.p58),
              Text(
                'Turno rimosso',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  fontSize: AppSizes.p32,
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
                  fontSize: AppSizes.p20,
                  height: 1.16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width:
                    double.infinity, // Adapted from 340, keeping it responsive
                height: AppSizes.p53_28,
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        AppColors.brandPrimary,
                        AppColors.textOnDark,
                        0.30,
                      )!,
                      AppColors.brandPrimary,
                      Color.lerp(
                        AppColors.brandPrimary,
                        AppColors.darkBackground,
                        0.18,
                      )!,
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
                      color: AppColors.transparent,
                      blurRadius: AppSizes.p4,
                      offset: Offset(0, 4),
                      spreadRadius: AppSizes.p0,
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/turni'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors
                        .transparent, // Make button background transparent to show gradient
                    foregroundColor: AppColors
                        .transparent, // Text color handled by Text widget
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
                        AppColors.transparent, // Remove default button shadow
                  ),
                  child: const Text(
                    // Use const for performance
                    'Torna ai turni',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // As per requested style
                      color: AppColors.textOnDark,
                      fontSize: AppSizes.p22,
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
    color: AppColors.dividerDark,
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
