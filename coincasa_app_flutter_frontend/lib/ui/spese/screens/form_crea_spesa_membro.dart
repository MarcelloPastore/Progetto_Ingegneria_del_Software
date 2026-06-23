import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/auth_user.dart';
import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/app_switch.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/ui/spese/screens/spesa_inserita_successo.dart';
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';

Future<void> showInserisciSpesaMembroDialog(BuildContext context) {
  final screenSize = MediaQuery.sizeOf(context);
  final popupWidth = screenSize.width < 399 ? screenSize.width - 32 : 367.0;
  final popupHeight = screenSize.height < 690 ? screenSize.height - 64 : 638.0;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.darkBackground.withValues(alpha: 0.56),
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p24,
      ),
      backgroundColor: AppColors.transparent,
      child: Container(
        width: popupWidth,
        height: popupHeight,
        decoration: ShapeDecoration(
          color: AppColors.textOnDark,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: AppSizes.p2,
              color: AppColors.featureAccent,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius15),
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadowOverlay,
              blurRadius: AppSizes.p4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radius13),
          child: const InserisciSpesaMembroPopupContent(),
        ),
      ),
    ),
  );
}

class InserisciSpesaMembroScreen extends ConsumerStatefulWidget {
  const InserisciSpesaMembroScreen({super.key});

  static const String routeName = '/spese/nuovo-membro';

  @override
  ConsumerState<InserisciSpesaMembroScreen> createState() =>
      _InserisciSpesaMembroScreenState();
}

class InserisciSpesaMembroPopupContent extends ConsumerStatefulWidget {
  const InserisciSpesaMembroPopupContent({super.key});

  @override
  ConsumerState<InserisciSpesaMembroPopupContent> createState() =>
      _InserisciSpesaMembroPopupContentState();
}

class _InserisciSpesaMembroScreenState
    extends ConsumerState<InserisciSpesaMembroScreen>
    with _InserisciSpesaMembroFormMixin<InserisciSpesaMembroScreen> {
  @override
  bool get _isPopup => false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(child: _buildContent()),
    );
  }
}

class _InserisciSpesaMembroPopupContentState
    extends ConsumerState<InserisciSpesaMembroPopupContent>
    with _InserisciSpesaMembroFormMixin<InserisciSpesaMembroPopupContent> {
  @override
  bool get _isPopup => true;

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}

mixin _InserisciSpesaMembroFormMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  final _importoController = TextEditingController();
  final _descrizioneController = TextEditingController();
  late Future<_MemberExpenseData?> _future;
  bool _initialized = false;
  bool _paidForAll = true;
  bool _isSubmitting = false;
  bool _showErrors = false;
  DateTime _date = DateTime.now();
  final Set<String> _selectedIds = <String>{};

  bool get _isPopup;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _future = _loadData();
  }

  @override
  void dispose() {
    _importoController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<_MemberExpenseData?> _loadData() async {
    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ref.read(listaCaseViewModelProvider.future);
    if (caseUtente.isEmpty) {
      return null;
    }
    final casa = activeCasaController.resolveCasa(caseUtente);
    final state = await ref.read(speseViewModelProvider(casa.id).future);
    final currentUser = await ref.read(authViewModelProvider.future);
    final inquilini = state.inquilini;
    final current = _resolveCurrentUser(inquilini, currentUser);

    if (mounted && _selectedIds.isEmpty) {
      setState(() {
        final currentId = current?.id;
        if (currentId != null && currentId.isNotEmpty) {
          _selectedIds.add(currentId);
        }
      });
    }

    return _MemberExpenseData(
      casa: casa,
      inquilini: inquilini,
      currentUserId: current?.id,
    );
  }

  Inquilino? _resolveCurrentUser(
    List<Inquilino> inquilini,
    AuthUser? currentUser,
  ) {
    // 1. Usa l'ID utente dalla sessione — identificatore univoco, non ambiguo.
    final userId = currentUser?.id.trim();
    if (userId != null && userId.isNotEmpty) {
      for (final inquilino in inquilini) {
        if (inquilino.id == userId) {
          return inquilino;
        }
      }
    }

    // 2. Fallback: email (univoca per definizione).
    final email = currentUser?.email.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      for (final inquilino in inquilini) {
        if (inquilino.email.trim().toLowerCase() == email) {
          return inquilino;
        }
      }
    }

    // Non usiamo nome/nomeCompleto: non sono univoci e causano falsi positivi
    // quando due utenti condividono lo stesso nome anagrafico.
    return null;
  }

  double? get _parsedAmount {
    final normalized = _importoController.text.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  bool get _hasAmountError {
    final amount = _parsedAmount;
    return _showErrors && (amount == null || amount <= 0);
  }

  bool get _hasParticipantsError => _showErrors && _selectedIds.isEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit(_MemberExpenseData data) async {
    FocusScope.of(context).unfocus();
    setState(() => _showErrors = true);

    final amount = _parsedAmount;
    if (amount == null || amount <= 0 || _selectedIds.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(speseViewModelProvider(data.casa.id).notifier)
          .createSpesaFromFields(
            descrizione: _descrizioneController.text,
            importo: _importoController.text,
            partecipanti: _selectedIds,
            data: _date,
            currentUserId: data.currentUserId,
            anticipataPerTutti: _paidForAll,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        InserisciSpesaSuccessoScreen.routeName,
        arguments: InserisciSpesaSuccessoArgs(memberFlow: true),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile salvare la spesa. Riprova.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildContent() {
    return Container(
      color: _isPopup ? AppColors.textOnDark : AppColors.transparent,
      child: FutureBuilder<_MemberExpenseData?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.featureAccent),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return Center(
              child: Text(
                'Dati non disponibili.',
                style: TextStyle(
                  color: _isPopup
                      ? AppColors.surfaceDarkMuted
                      : AppColors.textOnDark,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSizes.p13,
              _isPopup ? AppSizes.p16 : AppSizes.p18,
              AppSizes.p13,
              AppSizes.p24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (_isPopup
                    ? 0
                    : MediaQuery.sizeOf(context).height -
                          MediaQuery.paddingOf(context).vertical -
                          103),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BackTitle(
                    popup: _isPopup,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(height: _isPopup ? 16 : 22),
                  if (_hasAmountError) ...[
                    const _ErrorText(
                      message: 'Inserisci un importo valido per continuare',
                      leftPadding: 0,
                    ),
                    const SizedBox(height: AppSizes.p7),
                  ],
                  _AmountField(
                    controller: _importoController,
                    hasError: _hasAmountError,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSizes.p7),
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(date: _date, onTap: _pickDate),
                      ),
                      const SizedBox(width: AppSizes.p7),
                      Expanded(
                        flex: 12,
                        child: _DescriptionField(
                          controller: _descrizioneController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p18),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSizes.p24),
                    child: Text(
                      'DIVIDI TRA',
                      style: TextStyle(
                        color: _isPopup
                            ? AppColors.brandPrimaryDark
                            : AppColors.textDisabled,
                        fontSize: AppSizes.p20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  _ParticipantsCard(
                    inquilini: data.inquilini,
                    selectedIds: _selectedIds,
                    currentUserId: data.currentUserId,
                    amount: _parsedAmount,
                    hasError: _hasParticipantsError,
                    onToggle: (id) {
                      if (id == data.currentUserId) {
                        return;
                      }
                      setState(() {
                        if (_selectedIds.contains(id)) {
                          _selectedIds.remove(id);
                        } else {
                          _selectedIds.add(id);
                        }
                      });
                    },
                  ),
                  if (_hasParticipantsError) ...[
                    const SizedBox(height: AppSizes.p7),
                    const _ErrorText(
                      message: 'Seleziona almeno un coinquilino',
                      leftPadding: 38,
                    ),
                  ],
                  const SizedBox(height: AppSizes.p18),
                  _MemberSwitchRow(
                    title: 'Ho anticipato per tutti',
                    subtitle: 'Gli altri vedranno il debito verso di te',
                    value: _paidForAll,
                    popup: _isPopup,
                    onChanged: (value) => setState(() => _paidForAll = value),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  _RecurringDisabledRow(popup: _isPopup),
                  if (!_isPopup) const Spacer(),
                  SizedBox(height: _isPopup ? 22 : 34),
                  _SubmitButton(
                    isSubmitting: _isSubmitting,
                    onPressed: () => _submit(data),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  _CancelButton(
                    enabled: !_isSubmitting,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BackTitle extends StatelessWidget {
  const _BackTitle({required this.onBack, required this.popup});

  final VoidCallback onBack;
  final bool popup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(AppSizes.radius20),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.featureAccent,
            size: AppSizes.p25,
          ),
        ),
        const SizedBox(width: AppSizes.p2),
        Text(
          popup ? 'Nuova Spesa' : 'Spese',
          style: TextStyle(
            color: AppColors.featureAccent,
            fontSize: AppSizes.p22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AmountField extends StatefulWidget {
  const _AmountField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _focusNode.requestFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: AppSizes.p73,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkMuted,
          border: Border.all(
            color: widget.hasError
                ? AppColors.errorStrong
                : _hasFocus
                ? AppColors.featureAccent
                : AppColors.textMutedSoft,
            width: widget.hasError || _hasFocus ? 2 : 1.8,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius9),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.featureAccent.withValues(alpha: 0.22),
                    blurRadius: AppSizes.p14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Stack(
          children: [
            Positioned(
              left: AppSizes.p11,
              top: AppSizes.p5,
              child: Text(
                'Importo',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: AppSizes.p21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned.fill(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-0-9,.]')),
                ],
                textAlign: TextAlign.right,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.featureAccent,
                  fontSize: AppSizes.p38,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(
                    AppSizes.p12,
                    AppSizes.p22,
                    AppSizes.p11,
                    AppSizes.p0,
                  ),
                  prefixText: widget.controller.text.trim().isEmpty ? '' : '€ ',
                  prefixStyle: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.featureAccent,
                    fontSize: AppSizes.p38,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: '€ 0,00',
                  hintStyle: AppTextStyles.screenTitleStrong.copyWith(
                    color: AppColors.featureAccent,
                    fontSize: AppSizes.p38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return _MiniFieldButton(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_month,
            color: AppColors.textOnDark,
            size: AppSizes.p18,
          ),
          const SizedBox(width: AppSizes.p5),
          Flexible(
            child: Text(
              formatted,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _MiniFieldButton(
      child: Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: AppColors.textOnDark.withValues(alpha: 0.7),
            size: AppSizes.p20,
          ),
          const SizedBox(width: AppSizes.p6),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Descrizione',
                hintStyle: TextStyle(
                  color: AppColors.textOnDark.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSizes.p4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFieldButton extends StatelessWidget {
  const _MiniFieldButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius7),
      child: Container(
        height: AppSizes.p46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkMuted,
          border: Border.all(
            color: AppColors.textMutedSoft,
            width: AppSizes.p1_8,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius7),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
        child: child,
      ),
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({
    required this.inquilini,
    required this.selectedIds,
    required this.currentUserId,
    required this.amount,
    required this.hasError,
    required this.onToggle,
  });

  final List<Inquilino> inquilini;
  final Set<String> selectedIds;
  final String? currentUserId;
  final double? amount;
  final bool hasError;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkCardAlt,
        border: Border.all(
          color: hasError ? AppColors.errorStrong : AppColors.textMutedSoft,
          width: hasError ? 2 : 1.8,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius10),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p8,
        AppSizes.p16,
        AppSizes.p7,
      ),
      child: Column(
        children: [
          for (int index = 0; index < inquilini.length; index++) ...[
            _ParticipantRow(
              inquilino: inquilini[index],
              selected: selectedIds.contains(inquilini[index].id),
              isCurrentUser: inquilini[index].id == currentUserId,
              amount: _shareAmount,
              onToggle: () => onToggle(inquilini[index].id),
            ),
            if (index < inquilini.length - 1)
              const Divider(
                height: AppSizes.p1,
                color: AppColors.textMutedDark,
              ),
          ],
        ],
      ),
    );
  }

  double? get _shareAmount {
    final value = amount;
    if (value == null || value <= 0 || selectedIds.isEmpty) {
      return null;
    }
    return value / selectedIds.length;
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.inquilino,
    required this.selected,
    required this.isCurrentUser,
    required this.amount,
    required this.onToggle,
  });

  final Inquilino inquilino;
  final bool selected;
  final bool isCurrentUser;
  final double? amount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final label = _displayName(inquilino);
    final muted = isCurrentUser;
    return InkWell(
      onTap: isCurrentUser ? null : onToggle,
      child: SizedBox(
        height: AppSizes.p46,
        child: Row(
          children: [
            UserAvatar(displayName: label, radius: 18),
            const SizedBox(width: AppSizes.p14),
            Expanded(
              child: Text(
                isCurrentUser ? '$label (Tu)' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted ? AppColors.textMutedDark : AppColors.textOnDark,
                  fontSize: AppSizes.p13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: isCurrentUser ? null : (_) => onToggle(),
              activeColor: AppColors.brandPrimaryDark,
              checkColor: AppColors.textOnDark,
              side: const BorderSide(
                color: AppColors.textMutedDark,
                width: AppSizes.p2,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(
              width: AppSizes.p37,
              child: Text(
                selected && amount != null
                    ? '€${amount!.toStringAsFixed(0)}'
                    : '-',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: AppSizes.p16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberSwitchRow extends StatelessWidget {
  const _MemberSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.popup,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool popup;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: popup ? AppColors.dividerDark : AppColors.textDisabled,
                  fontSize: AppSizes.p17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: popup
                      ? AppColors.textMutedDark
                      : AppColors.textMutedDark,
                  fontSize: AppSizes.p12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        AppSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _RecurringDisabledRow extends StatelessWidget {
  const _RecurringDisabledRow({required this.popup});

  final bool popup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spesa ricorrente',
                style: TextStyle(
                  color: popup
                      ? AppColors.textMutedDark
                      : AppColors.textMutedDark,
                  fontSize: AppSizes.p17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Ripete seguendo la data precedente',
                style: TextStyle(
                  color: popup
                      ? AppColors.textMutedDark
                      : AppColors.textMutedDark,
                  fontSize: AppSizes.p12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '( solo HomeAdmin )',
                    style: TextStyle(
                      color: AppColors.warningDark,
                      fontSize: AppSizes.p12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: AppSizes.p4),
                  Icon(
                    Icons.warning,
                    color: AppColors.warningDark,
                    size: AppSizes.p13,
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSwitch(value: false, onChanged: null),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.p56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.brandSecondary, AppColors.brandPrimaryDark],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius15),
        border: Border.all(
          color: AppColors.textMutedDark,
          width: AppSizes.p1_7,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: AppSizes.p4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          disabledBackgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius15),
          ),
        ),
        child: Text(
          isSubmitting ? 'Salvataggio...' : 'Conferma e aggiungi',
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: AppSizes.p22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p28),
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.errorContainerStrong,
          foregroundColor: AppColors.errorStrong,
          side: const BorderSide(
            color: AppColors.errorStrong,
            width: AppSizes.p2,
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius18),
          ),
          disabledForegroundColor: AppColors.textMuted.withValues(alpha: 0.42),
        ),
        child: Text(
          'Annulla',
          style: AppTextStyles.buttonCompact.copyWith(
            color: AppColors.errorStrong,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message, required this.leftPadding});

  final String message;
  final double leftPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Row(
        children: [
          const Icon(
            Icons.error,
            color: AppColors.errorStrong,
            size: AppSizes.p16,
          ),
          const SizedBox(width: AppSizes.p7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.errorStrong,
                fontSize: AppSizes.p16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberExpenseData {
  const _MemberExpenseData({
    required this.casa,
    required this.inquilini,
    required this.currentUserId,
  });

  final Casa casa;
  final List<Inquilino> inquilini;
  final String? currentUserId;
}

String _displayName(Inquilino inquilino) {
  final username = inquilino.username.trim();
  if (username.isNotEmpty) return username;
  if (inquilino.email.trim().isNotEmpty) return inquilino.email.trim();
  return 'Coinquilino';
}
