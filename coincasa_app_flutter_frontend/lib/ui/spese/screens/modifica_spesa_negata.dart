import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/data/models/quota.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/formatters.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/app_switch.dart';
import 'package:coincasa_app/core/widgets/common/screen_back_header.dart';
import 'package:coincasa_app/ui/spese/screens/modifica_spesa_successo.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';

class ModificheSpeseNegataScreen extends ConsumerStatefulWidget {
  const ModificheSpeseNegataScreen({super.key});

  static const String routeName = '/spese/modifica-negata';

  @override
  ConsumerState<ModificheSpeseNegataScreen> createState() =>
      _ModificheSpeseNegataScreenState();
}

class _ModificheSpeseNegataScreenState
    extends ConsumerState<ModificheSpeseNegataScreen> {
  late Future<_EditData?> _future;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _date = DateTime(2026, 6, 15);
  bool _paidForAll = true;
  bool _recurring = false;
  String _frequency = 'Mensile';
  Set<String> _selectedIds = {};
  bool _initialized = false;
  bool _submitting = false;

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
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<_EditData?> _loadData() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final spesaId = args is Spesa ? args.id : args?.toString();
    if (spesaId == null || spesaId.isEmpty) {
      return null;
    }

    final activeCasaController = ActiveCasaScope.read(context);
    final caseUtente = await ref.read(listaCaseViewModelProvider.future);
    if (caseUtente.isEmpty) {
      return null;
    }
    final casa = activeCasaController.resolveCasa(caseUtente);
    final state = await ref.read(speseViewModelProvider(casa.id).future);
    final notifier = ref.read(speseViewModelProvider(casa.id).notifier);
    final results = await Future.wait<dynamic>([
      args is Spesa
          ? Future<Spesa>.value(args)
          : notifier.getSpesaById(spesaId),
      notifier.getQuoteSpesa(spesaId).catchError((_) => const <Quota>[]),
    ]);

    final spesa = results[0] as Spesa;
    final inquilini = state.inquilini;
    final quote = results[1] as List<Quota>;
    _amountController.text = spesa.importo
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    _descriptionController.text = spesa.descrizione;
    _date = spesa.data;
    _recurring = spesa.isRicorrente;
    _selectedIds = _selectedFrom(spesa, quote, inquilini);

    return _EditData(
      casa: casa,
      spesa: spesa,
      inquilini: inquilini,
      quote: quote,
    );
  }

  Set<String> _selectedFrom(
    Spesa spesa,
    List<Quota> quote,
    List<Inquilino> inquilini,
  ) => selectedParticipantIds(spesa, quote, inquilini);

  Future<void> _submit(_EditData data) async {
    if (_submitting || _selectedIds.isEmpty) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final updated = await ref
          .read(speseViewModelProvider(data.casa.id).notifier)
          .updateSpesaFromFields(
            idSpesa: data.spesa.id,
            descrizione: _descriptionController.text,
            importo: _amountController.text,
            partecipanti: _selectedIds,
            data: _date,
            currentUserId: data.spesa.creatoreId,
            anticipataPerTutti: _paidForAll,
            ricorrente: _recurring,
            frequenza: _frequency,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        ModificheSpeseSuccessoScreen.routeName,
        arguments: updated,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile salvare le modifiche.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: FutureBuilder<_EditData?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('Spesa non disponibile.'));
            }
            if (data.quote.any((quota) => quota.pagata)) {
              return _ProtectedEditContent(data: data);
            }
            return _EditFormContent(
              data: data,
              amountController: _amountController,
              descriptionController: _descriptionController,
              date: _date,
              selectedIds: _selectedIds,
              paidForAll: _paidForAll,
              recurring: _recurring,
              frequency: _frequency,
              submitting: _submitting,
              onDateChanged: (date) => setState(() => _date = date),
              onToggleInquilino: (id) => setState(() {
                _selectedIds = {..._selectedIds};
                _selectedIds.contains(id)
                    ? _selectedIds.remove(id)
                    : _selectedIds.add(id);
              }),
              onPaidForAllChanged: (value) =>
                  setState(() => _paidForAll = value),
              onRecurringChanged: (value) => setState(() => _recurring = value),
              onFrequencyChanged: (value) => setState(() => _frequency = value),
              onSubmit: () => _submit(data),
            );
          },
        ),
      ),
    );
  }
}

class _EditFormContent extends StatelessWidget {
  const _EditFormContent({
    required this.data,
    required this.amountController,
    required this.descriptionController,
    required this.date,
    required this.selectedIds,
    required this.paidForAll,
    required this.recurring,
    required this.frequency,
    required this.submitting,
    required this.onDateChanged,
    required this.onToggleInquilino,
    required this.onPaidForAllChanged,
    required this.onRecurringChanged,
    required this.onFrequencyChanged,
    required this.onSubmit,
  });

  final _EditData data;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final DateTime date;
  final Set<String> selectedIds;
  final bool paidForAll;
  final bool recurring;
  final String frequency;
  final bool submitting;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onToggleInquilino;
  final ValueChanged<bool> onPaidForAllChanged;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<String> onFrequencyChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p10,
        AppSizes.p20,
        AppSizes.p22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenBackHeader(
            title: 'Spese',
            onBack: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSizes.p16),
          const _WarningBox(),
          const SizedBox(height: AppSizes.p14),
          _AmountBox(controller: amountController),
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              Expanded(
                child: _DateBox(date: date, onChanged: onDateChanged),
              ),
              const SizedBox(width: AppSizes.p8),
              Expanded(
                child: _DescriptionBox(controller: descriptionController),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p14),
          Text(
            'DIVIDI TRA',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.textSubtle,
              fontSize: AppSizes.p23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          _RoommatesBox(
            inquilini: data.inquilini,
            selectedIds: selectedIds,
            total: _parseAmount(amountController.text),
            onToggle: onToggleInquilino,
          ),
          const SizedBox(height: AppSizes.p12),
          _SwitchRow(
            title: 'Ho anticipato per tutti',
            subtitle: 'Gli altri vedranno il debito verso di te.',
            value: paidForAll,
            onChanged: onPaidForAllChanged,
          ),
          _SwitchRow(
            title: 'Spesa ricorrente',
            subtitle: 'Ripete automaticamente',
            value: recurring,
            onChanged: onRecurringChanged,
          ),
          Text(
            'Frequenza',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: recurring
                  ? AppColors.brandAccent
                  : AppColors.textMutedDark,
              fontSize: AppSizes.p23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p6),
          _FrequencyBox(
            value: frequency,
            enabled: recurring,
            onChanged: onFrequencyChanged,
          ),
          const SizedBox(height: AppSizes.p14),
          const Divider(color: AppColors.borderMuted),
          const SizedBox(height: AppSizes.p14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: submitting ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                    ),
                  ),
                  child: Text(
                    submitting ? 'Salvataggio...' : 'Salva modifiche',
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: AppSizes.p18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p10),
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.brandPrimary,
                      width: AppSizes.p2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                    ),
                  ),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(
                      color: AppColors.brandPrimary,
                      fontSize: AppSizes.p18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtectedEditContent extends StatelessWidget {
  const _ProtectedEditContent({required this.data});

  final _EditData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p28,
        AppSizes.p24,
        AppSizes.p28,
        AppSizes.p28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenBackHeader(
            title: 'Dettaglio spesa',
            onBack: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSizes.p42),
          Text(
            formatCurrency(data.spesa.importo),
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong.copyWith(
              fontSize: AppSizes.p38,
            ),
          ),
          const SizedBox(height: AppSizes.p6),
          Text(
            '${data.spesa.descrizione} - ${formatLongDate(data.spesa.data)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: AppSizes.p18,
            ),
          ),
          const SizedBox(height: AppSizes.p28),
          _SimpleSummary(data: data),
          Transform.translate(
            offset: const Offset(0, -2),
            child: const _ProtectedCard(
              color: AppColors.warning,
              icon: Icons.edit_off,
              title: 'Impossibile modificare la spesa',
              message:
                  'Questa spesa ha quote già pagate da uno o più coinquilini. Non è possibile modificarla per non alterare i pagamenti già registrati.',
              pillText: 'Spesa protetta da pagamenti esistenti',
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p10,
      ),
      decoration: BoxDecoration(
        color: AppColors.turniAssigneeDivider,
        border: Border.all(color: AppColors.warning, width: AppSizes.p3),
        borderRadius: BorderRadius.circular(AppSizes.radius4),
      ),
      child: const Text(
        'Stai modificando una spesa esistente. Le modifiche saranno visibili a tutti i coinquilini.',
        style: TextStyle(color: AppColors.warning, fontSize: AppSizes.p16),
      ),
    );
  }
}

class _AmountBox extends StatelessWidget {
  const _AmountBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _fieldDecoration(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p10,
        AppSizes.p6,
        AppSizes.p18,
        AppSizes.p6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Importo',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p20,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.brandAccent,
              fontSize: AppSizes.p39,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixText: '€ ',
              prefixStyle: TextStyle(color: AppColors.brandAccent),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      icon: const Icon(
        Icons.calendar_month,
        color: AppColors.textOnDark,
        size: AppSizes.p18,
      ),
      label: Text(
        formatShortDate(date),
        style: const TextStyle(
          color: AppColors.textOnDark,
          fontSize: AppSizes.p17,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: AppColors.textMutedDark,
          width: AppSizes.p2,
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
      ),
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  const _DescriptionBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textOnDark,
        fontSize: AppSizes.p17,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceDarkMuted,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSizes.p12,
          horizontal: AppSizes.p8,
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(
            color: AppColors.textMutedDark,
            width: AppSizes.p2,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: AppColors.textMutedDark,
            width: AppSizes.p2,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
      ),
    );
  }
}

class _RoommatesBox extends StatelessWidget {
  const _RoommatesBox({
    required this.inquilini,
    required this.selectedIds,
    required this.total,
    required this.onToggle,
  });

  final List<Inquilino> inquilini;
  final Set<String> selectedIds;
  final double total;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final selectedCount = selectedIds.isEmpty ? 1 : selectedIds.length;
    final share = total / selectedCount;
    return Container(
      decoration: _fieldDecoration(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p20,
        vertical: AppSizes.p10,
      ),
      child: Column(
        children: [
          for (int index = 0; index < inquilini.length; index++) ...[
            _RoommateRow(
              inquilino: inquilini[index],
              selected: selectedIds.contains(inquilini[index].id),
              share: share,
              onTap: () => onToggle(inquilini[index].id),
            ),
            if (index < inquilini.length - 1)
              const Divider(color: AppColors.borderMuted, height: AppSizes.p10),
          ],
        ],
      ),
    );
  }
}

class _RoommateRow extends StatelessWidget {
  const _RoommateRow({
    required this.inquilino,
    required this.selected,
    required this.share,
    required this.onTap,
  });

  final Inquilino inquilino;
  final bool selected;
  final double share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = inquilino.username.isNotEmpty
        ? inquilino.username
        : inquilino.email;
    final initials = _initials(name);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _avatarColor(initials),
              child: Text(
                initials,
                style: const TextStyle(color: AppColors.textOnDark),
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: AppSizes.p15,
                ),
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.brandPrimary,
            ),
            Text(
              formatCurrency(share),
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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
                  color: AppColors.textDisabled,
                  fontSize: AppSizes.p20,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMutedDark,
                  fontSize: AppSizes.p13,
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

class _FrequencyBox extends StatelessWidget {
  const _FrequencyBox({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      'Mensile',
      'Bimestrale',
      'Trimestrale',
      'Annuale',
      'Personalizzata',
    ];
    return SizedBox(
      width: AppSizes.p240,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p14),
        decoration: _fieldDecoration(
          borderColor: enabled
              ? AppColors.textMutedDark
              : AppColors.textMutedDark,
          fillColor: enabled
              ? AppColors.surfaceDarkMuted
              : AppColors.surfaceDarkCard,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.contains(value) ? value : options.first,
            dropdownColor: AppColors.dividerDark,
            iconEnabledColor: enabled
                ? AppColors.brandAccent
                : AppColors.textMutedDark,
            iconDisabledColor: AppColors.textMutedDark,
            isExpanded: true,
            items: options
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        color: enabled
                            ? AppColors.textDisabled
                            : AppColors.borderSubtle,
                        fontSize: AppSizes.p16,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled
                ? (next) {
                    if (next != null) {
                      onChanged(next);
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class _SimpleSummary extends StatelessWidget {
  const _SimpleSummary({required this.data});

  final _EditData data;

  @override
  Widget build(BuildContext context) {
    final projection = SpesaDetailProjection.from(
      spesa: data.spesa,
      quote: data.quote,
      inquilini: data.inquilini,
      currentUserId: null,
    );
    final names = projection.rows.map((row) => row.name).toList();
    final share = projection.quotaPerPersona;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textMutedSoft),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Chi deve pagare',
            value: names.isEmpty ? 'Marco, Emilia' : names.join(', '),
          ),
          const Divider(color: AppColors.borderMuted),
          _SummaryRow(label: 'Quota per persone', value: formatCurrency(share)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: AppSizes.p18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: AppSizes.p18,
          ),
        ),
      ],
    );
  }
}

class _ProtectedCard extends StatelessWidget {
  const _ProtectedCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    required this.pillText,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final String pillText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.p385),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p18,
        AppSizes.p10,
        AppSizes.p18,
        AppSizes.p24,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        border: Border.all(color: color, width: AppSizes.p2),
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.errorStrong,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textOnDark,
                  size: AppSizes.p19,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: AppSizes.p66),
                const SizedBox(height: AppSizes.p22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: AppSizes.p20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: AppSizes.p18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.p28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p16,
                    vertical: AppSizes.p8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: AppSizes.p1_4),
                    borderRadius: BorderRadius.circular(AppSizes.radius30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: color, size: AppSizes.p18),
                      const SizedBox(width: AppSizes.p8),
                      Text(
                        pillText,
                        style: TextStyle(color: color, fontSize: AppSizes.p13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditData {
  const _EditData({
    required this.casa,
    required this.spesa,
    required this.inquilini,
    required this.quote,
  });

  final Casa casa;
  final Spesa spesa;
  final List<Inquilino> inquilini;
  final List<Quota> quote;
}

BoxDecoration _fieldDecoration({
  Color fillColor = AppColors.surfaceDarkMuted,
  Color borderColor = AppColors.textMutedDark,
}) {
  return BoxDecoration(
    color: fillColor,
    border: Border.all(color: borderColor, width: AppSizes.p2),
    borderRadius: BorderRadius.circular(AppSizes.radius10),
  );
}

double _parseAmount(String value) {
  return double.tryParse(value.replaceAll(',', '.')) ?? 0;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'C';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

Color _avatarColor(String initials) {
  const colors = [
    AppColors.info,
    AppColors.statusPositive,
    AppColors.statusWarning,
    AppColors.statusNegative,
  ];
  return colors[initials.codeUnitAt(0) % colors.length];
}
