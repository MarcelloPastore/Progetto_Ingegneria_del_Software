import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/turni/screens/assegna_a_me.dart';

class DettaglioTurnoAdminScreen extends ConsumerStatefulWidget {
  const DettaglioTurnoAdminScreen({super.key});

  static const routeName = '/turni/dettaglio-admin';

  @override
  ConsumerState<DettaglioTurnoAdminScreen> createState() =>
      _DettaglioTurnoAdminScreenState();
}

class _DettaglioTurnoAdminScreenState
    extends ConsumerState<DettaglioTurnoAdminScreen> {
  bool _assigneeMenuOpen = false;
  bool _assignFutureTurns = true;
  bool _confirmDelete = false;
  bool _isSubmitting = false;
  String _selectedAssignee = 'Emma';

  String? get _turnoId {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is String && args.isNotEmpty ? args : null;
  }

  Future<String?> _activeCasaId() async {
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }
    return activeCasaController.resolveCasa(caseUtente).id;
  }

  Future<void> _handleAssignMe() async {
    final turnoId = _turnoId;
    if (turnoId == null) {
      Navigator.of(context).pushNamed(AssegnaAMeSuccessScreen.routeName);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final casaId = await _activeCasaId();
      if (casaId != null && mounted) {
        await ApiProvider.turni.autoAssegna(casaId, turnoId);
      }
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

  Future<void> _handleDelete() async {
    if (!_confirmDelete) {
      setState(() => _confirmDelete = true);
      return;
    }

    final turnoId = _turnoId;
    if (turnoId == null) {
      Navigator.of(context).pushReplacementNamed(TurnoRimossoScreen.routeName);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final casaId = await _activeCasaId();
      if (casaId != null && mounted) {
        await ApiProvider.turni.delete(casaId, turnoId);
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(TurnoRimossoScreen.routeName);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _confirmDelete = false;
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile eliminare il turno.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/turni'),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p14,
                AppSizes.p8,
                AppSizes.p14,
                AppSizes.p20,
              ),
              child: Opacity(
                opacity: _confirmDelete ? 0.42 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailHeader(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: AppSizes.p24),
                    const _TurnoSummaryCard(),
                    const SizedBox(height: AppSizes.p24),
                    const _ResponsibleCard(),
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
                      label: 'Assegna a me',
                      onPressed: _isSubmitting ? null : () => _handleAssignMe(),
                    ),
                    const SizedBox(height: AppSizes.p10),
                    _AssigneeSelector(
                      selectedAssignee: _selectedAssignee,
                      expanded: _assigneeMenuOpen,
                      onToggle: () => setState(
                        () => _assigneeMenuOpen = !_assigneeMenuOpen,
                      ),
                      onSelected: (value) {
                        setState(() {
                          _selectedAssignee = value;
                          _assigneeMenuOpen = false;
                        });
                      },
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text(
                      'I turni successivi non subiranno cambiamenti.\nSolo questo turno verra aggiornato.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textMutedLight.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p90),
                    _FutureTurnsToggle(
                      value: _assignFutureTurns,
                      onChanged: (value) =>
                          setState(() => _assignFutureTurns = value),
                    ),
                    const SizedBox(height: AppSizes.p40),
                    _DeleteTurnoButton(
                      confirmMode: _confirmDelete,
                      onPressed: _isSubmitting ? null : () => _handleDelete(),
                    ),
                  ],
                ),
              ),
            ),
            if (_confirmDelete)
              Positioned(
                left: AppSizes.p20,
                right: AppSizes.p20,
                top: 300,
                child: _DeleteWarningCard(
                  onTapOutside: () => setState(() => _confirmDelete = false),
                ),
              ),
          ],
        ),
      ),
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
  const _TurnoSummaryCard();

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
              text: 'Pulizie bagno\n',
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textOnDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: 'Ogni 7 giorni\nprossimo: oggi!',
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
  const _ResponsibleCard();

  @override
  Widget build(BuildContext context) {
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
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF2F8F46),
                child: Text(
                  'FP',
                  style: TextStyle(
                    color: Color(0xFF66FF7B),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Francesco',
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: const Color(0xFF20F545),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.textOnDark,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      child: Text(
        label,
        style: AppTextStyles.buttonCompact.copyWith(
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AssigneeSelector extends StatelessWidget {
  const _AssigneeSelector({
    required this.selectedAssignee,
    required this.expanded,
    required this.onToggle,
    required this.onSelected,
  });

  final String selectedAssignee;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelected;

  static const _options = ['Emilia', 'Marco', 'Luigi'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p27),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onToggle,
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
                    child: Icon(
                      Icons.front_hand_rounded,
                      color: Color(0xFF7B4BD3),
                      size: 21,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Assegna a $selectedAssignee',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.warning,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.warning,
                    size: 25,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Positioned(
              right: AppSizes.p0,
              top: 45,
              child: _AssigneeMenu(options: _options, onSelected: onSelected),
            ),
        ],
      ),
    );
  }
}

class _AssigneeMenu extends StatelessWidget {
  const _AssigneeMenu({required this.options, required this.onSelected});

  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: Container(
        width: AppSizes.p100,
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
                  onTap: () => onSelected(option),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    child: Text(
                      option,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.warning,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
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

class _FutureTurnsToggle extends StatelessWidget {
  const _FutureTurnsToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'assegna anche i turni successivi',
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textMutedLight,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textMutedLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.textOnDark,
          activeTrackColor: AppColors.brandAccent,
          inactiveThumbColor: AppColors.textMutedLight,
          inactiveTrackColor: AppColors.dividerDark,
        ),
      ],
    );
  }
}

class _DeleteTurnoButton extends StatelessWidget {
  const _DeleteTurnoButton({
    required this.confirmMode,
    required this.onPressed,
  });

  final bool confirmMode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: confirmMode
            ? AppColors.errorStrong.withValues(alpha: 0.24)
            : const Color(0xFF99000D),
        foregroundColor: AppColors.errorStrong,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: confirmMode
              ? const BorderSide(color: AppColors.errorStrong, width: 2.2)
              : BorderSide.none,
        ),
        elevation: confirmMode ? 0 : AppSizes.p6,
      ),
      child: Text(
        'Elimina turno',
        style: AppTextStyles.buttonCompact.copyWith(
          color: AppColors.errorStrong,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DeleteWarningCard extends StatelessWidget {
  const _DeleteWarningCard({required this.onTapOutside});

  final VoidCallback onTapOutside;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapOutside,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5A2F0D),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(color: AppColors.warning, width: 2),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p14,
          AppSizes.p20,
          AppSizes.p14,
          AppSizes.p24,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_rounded,
                  color: AppColors.warning,
                  size: 23,
                ),
                const SizedBox(width: AppSizes.p8),
                Text(
                  'Rimozione turno',
                  style: AppTextStyles.screenTitleStrong.copyWith(
                    color: const Color(0xFFFFD58A),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),
            Text(
              "Stai per eliminare questo turno.\n"
              "L'azione non puo essere annullata.\n"
              "Se procedi, verranno aggiornate\n"
              "anche le occorrenze future.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                color: const Color(0xFFFFE1A5),
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/turni'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandAccent,
                  side: const BorderSide(
                    color: AppColors.brandSecondary,
                    width: 1.8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                ),
                child: Text(
                  'Torna ai turni',
                  style: AppTextStyles.buttonCompact.copyWith(
                    color: AppColors.brandAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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
