import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/inserisci_spesa_successo.dart';

class InserisciSpesaMembroScreen extends StatefulWidget {
  const InserisciSpesaMembroScreen({super.key});

  static const String routeName = '/spese/nuovo-membro';

  @override
  State<InserisciSpesaMembroScreen> createState() =>
      _InserisciSpesaMembroScreenState();
}

class _InserisciSpesaMembroScreenState
    extends State<InserisciSpesaMembroScreen> {
  final _importoController = TextEditingController();
  final _descrizioneController = TextEditingController();
  late Future<_MemberExpenseData?> _future;
  bool _initialized = false;
  bool _paidForAll = true;
  bool _isSubmitting = false;
  bool _showErrors = false;
  DateTime _date = DateTime(2026, 5, 15);
  final Set<String> _selectedIds = <String>{};

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
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }
    final casa = activeCasaController.resolveCasa(caseUtente);
    final inquilini = await ApiProvider.casa.listInquilini(casa.id);
    final current = _resolveCurrentUser(inquilini);

    if (mounted && _selectedIds.isEmpty) {
      setState(() {
        _selectedIds.addAll(inquilini.map((inquilino) => inquilino.id));
      });
    }

    return _MemberExpenseData(
      casa: casa,
      inquilini: inquilini,
      currentUserId: current?.id,
    );
  }

  Inquilino? _resolveCurrentUser(List<Inquilino> inquilini) {
    final email = ApiProvider.client.currentUserEmail?.trim().toLowerCase();
    final name = ApiProvider.client.currentUserName?.trim().toLowerCase();
    for (final inquilino in inquilini) {
      final values = [
        inquilino.email,
        inquilino.username,
        inquilino.nome,
        inquilino.nomeCompleto,
      ].map((value) => value.trim().toLowerCase());
      if ((email != null && values.contains(email)) ||
          (name != null && values.contains(name))) {
        return inquilino;
      }
    }
    return inquilini.isNotEmpty ? inquilini.first : null;
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
      await ApiProvider.spese.create(data.casa.id, {
        'descrizione': _descrizioneController.text.trim(),
        'importo': amount,
        'data': _date.toIso8601String(),
        'partecipanti': _selectedIds.toList(),
        'hoAnticipatoPerTutti': _paidForAll,
        'isRicorrente': false,
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151127),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: FutureBuilder<_MemberExpenseData?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(
                child: Text(
                  'Dati non disponibili.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(13, 18, 13, 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      103,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BackTitle(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 22),
                    if (_hasAmountError) ...[
                      const _ErrorText(
                        message: 'Inserisci un importo valido per continuare',
                        leftPadding: 0,
                      ),
                      const SizedBox(height: 7),
                    ],
                    _AmountField(
                      controller: _importoController,
                      hasError: _hasAmountError,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(date: _date, onTap: _pickDate),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          flex: 12,
                          child: _DescriptionField(
                            controller: _descrizioneController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: Text(
                        'DIVIDI TRA',
                        style: TextStyle(
                          color: Color(0xFFC1BFC8),
                          fontSize: 20,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ParticipantsCard(
                      inquilini: data.inquilini,
                      selectedIds: _selectedIds,
                      currentUserId: data.currentUserId,
                      amount: _parsedAmount,
                      hasError: _hasParticipantsError,
                      onToggle: (id) {
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
                      const SizedBox(height: 7),
                      const _ErrorText(
                        message: 'Seleziona almeno un coinquilino',
                        leftPadding: 38,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _MemberSwitchRow(
                      title: 'Ho anticipato per tutti',
                      subtitle: 'Gli altri vedranno il debito verso di te',
                      value: _paidForAll,
                      onChanged: (value) => setState(() => _paidForAll = value),
                    ),
                    const SizedBox(height: 12),
                    const _RecurringDisabledRow(),
                    const Spacer(),
                    const SizedBox(height: 34),
                    _SubmitButton(
                      isSubmitting: _isSubmitting,
                      onPressed: () => _submit(data),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BackTitle extends StatelessWidget {
  const _BackTitle({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(20),
          child: const Icon(
            Icons.arrow_back,
            color: Color(0xFF996CFA),
            size: 25,
          ),
        ),
        const SizedBox(width: 2),
        const Text(
          'Spese',
          style: TextStyle(
            color: Color(0xFF996CFA),
            fontSize: 22,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      decoration: BoxDecoration(
        color: const Color(0xFF312B4A),
        border: Border.all(
          color: hasError ? const Color(0xFFFF2525) : const Color(0xFFAAA6B2),
          width: hasError ? 2 : 1.8,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 11,
            top: 5,
            child: Text(
              'Importo',
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned.fill(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9,.]')),
              ],
              textAlign: TextAlign.right,
              style: AppTextStyles.screenTitleStrong.copyWith(
                color: const Color(0xFF996CFA),
                fontSize: 38,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(12, 22, 11, 0),
                prefixText: controller.text.trim().isEmpty ? '' : '€ ',
                prefixStyle: AppTextStyles.screenTitleStrong.copyWith(
                  color: const Color(0xFF996CFA),
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                ),
                hintText: '€ 0,00',
                hintStyle: AppTextStyles.screenTitleStrong.copyWith(
                  color: const Color(0xFF996CFA),
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
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
          const Icon(Icons.calendar_month, color: Colors.white, size: 18),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              formatted,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
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
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'Descrizione',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
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
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 37,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF312B4A),
          border: Border.all(color: const Color(0xFFAAA6B2), width: 1.8),
          borderRadius: BorderRadius.circular(7),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
        color: const Color(0xFF211C35),
        border: Border.all(
          color: hasError ? const Color(0xFFFF2525) : const Color(0xFFAAA6B2),
          width: hasError ? 2 : 1.8,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 7),
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
              const Divider(height: 1, color: Color(0xFF6E6879)),
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
      onTap: onToggle,
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            _Avatar(initials: _initials(label)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isCurrentUser ? '$label (Tu)' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted ? const Color(0xFF817B8C) : Colors.white,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF5A2CBD),
              checkColor: Colors.white,
              side: const BorderSide(color: Color(0xFF817B8C), width: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(
              width: 37,
              child: Text(
                selected && amount != null
                    ? '€${amount!.toStringAsFixed(0)}'
                    : '-',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Inter',
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
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
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
                style: const TextStyle(
                  color: Color(0xFFC1BFC8),
                  fontSize: 17,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8E8898),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF5A2CBD),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFF72717A),
        ),
      ],
    );
  }
}

class _RecurringDisabledRow extends StatelessWidget {
  const _RecurringDisabledRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spesa ricorrente',
                style: TextStyle(
                  color: Color(0xFF6F687C),
                  fontSize: 17,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Ripete seguendo la data precedente',
                style: TextStyle(
                  color: Color(0xFF6F687C),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '( solo HomeAdmin )',
                    style: TextStyle(
                      color: Color(0xFFC09A00),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.warning, color: Color(0xFFC09A00), size: 13),
                ],
              ),
            ],
          ),
        ),
        Switch(
          value: false,
          onChanged: null,
          inactiveThumbColor: const Color(0xFF9A98A0),
          inactiveTrackColor: const Color(0xFF57535F),
        ),
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
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF834BE0), Color(0xFF5526BA)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8D8A92), width: 1.7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          isSubmitting ? 'Salvataggio...' : 'Conferma e aggiungi',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'Inter',
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
          const Icon(Icons.error, color: Color(0xFFFF2525), size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFF2525),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _avatarColor(initials),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF58C9FF),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
        ),
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
  final fullName = inquilino.nomeCompleto.trim();
  if (fullName.isNotEmpty) {
    return fullName;
  }
  if (inquilino.username.trim().isNotEmpty) {
    return inquilino.username.trim();
  }
  if (inquilino.email.trim().isNotEmpty) {
    return inquilino.email.trim();
  }
  return 'Coinquilino';
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

Color _avatarColor(String initials) {
  const colors = [
    Color(0xFF2E6E9A),
    Color(0xFF478B54),
    Color(0xFFFFB085),
    Color(0xFFF16D70),
  ];
  return colors[initials.hashCode.abs() % colors.length];
}
