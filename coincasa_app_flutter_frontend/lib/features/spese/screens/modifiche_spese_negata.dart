import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/spese/screens/modifiche_spese_successo.dart';

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
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      return null;
    }
    final casa = activeCasaController.resolveCasa(caseUtente);
    final results = await Future.wait<dynamic>([
      args is Spesa
          ? Future<Spesa>.value(args)
          : ApiProvider.spese.getById(casa.id, spesaId),
      ApiProvider.casa
          .listInquilini(casa.id)
          .catchError((_) => const <Inquilino>[]),
      ApiProvider.spese
          .getQuote(casa.id, spesaId)
          .catchError((_) => const <Quota>[]),
    ]);

    final spesa = results[0] as Spesa;
    final inquilini = results[1] as List<Inquilino>;
    final quote = results[2] as List<Quota>;
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
  ) {
    final ids = <String>{};
    for (final quota in quote) {
      final id = quota.raw['inquilinoId'] ?? quota.raw['idInquilino'];
      if (id != null) {
        ids.add(id.toString());
      }
    }
    if (ids.isNotEmpty) {
      return ids;
    }
    for (final item in spesa.partecipanti) {
      final id = item['id'] ?? item['inquilinoId'] ?? item['idInquilino'];
      if (id != null) {
        ids.add(id.toString());
      }
    }
    return ids.isEmpty ? inquilini.map((item) => item.id).toSet() : ids;
  }

  Future<void> _submit(_EditData data) async {
    if (_submitting || _selectedIds.isEmpty) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final importo = double.parse(
        _amountController.text.trim().replaceAll(',', '.'),
      );
      final updated = await ApiProvider.spese
          .update(data.casa.id, data.spesa.id, {
            'descrizione': _descriptionController.text.trim(),
            'importo': importo,
            'data': _date.toIso8601String(),
            'partecipanti': _selectedIds.toList(),
            'hoAnticipatoPerTutti': _paidForAll,
            'isRicorrente': _recurring,
            if (_recurring) 'frequenza': _frequency,
          });
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
      backgroundColor: AppColors.darkBackground,
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackTitle(title: 'Spese', onBack: () => Navigator.of(context).pop()),
          const SizedBox(height: 16),
          const _WarningBox(),
          const SizedBox(height: 14),
          _AmountBox(controller: amountController),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateBox(date: date, onChanged: onDateChanged),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DescriptionBox(controller: descriptionController),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'DIVIDI TRA',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: const Color(0xFFAFAEAE),
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _RoommatesBox(
            inquilini: data.inquilini,
            selectedIds: selectedIds,
            total: _parseAmount(amountController.text),
            onToggle: onToggleInquilino,
          ),
          const SizedBox(height: 12),
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
                  : const Color(0xFF6A5A86),
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _FrequencyBox(
            value: frequency,
            enabled: recurring,
            onChanged: onFrequencyChanged,
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF807D7D)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: submitting ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                    ),
                  ),
                  child: Text(
                    submitting ? 'Salvataggio...' : 'Salva modifiche',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.brandPrimary,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                    ),
                  ),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(
                      color: AppColors.brandPrimary,
                      fontSize: 18,
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
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackTitle(
            title: 'Dettaglio spesa',
            onBack: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 42),
          Text(
            _formatCurrency(data.spesa.importo),
            textAlign: TextAlign.center,
            style: AppTextStyles.screenTitleStrong.copyWith(fontSize: 38),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.spesa.descrizione} - ${_formatLongDate(data.spesa.data)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFAFAEAE), fontSize: 18),
          ),
          const SizedBox(height: 28),
          _SimpleSummary(data: data),
          Transform.translate(
            offset: const Offset(0, -2),
            child: const _ProtectedCard(
              color: Color(0xFFFFD400),
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

class _BackTitle extends StatelessWidget {
  const _BackTitle({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.brandAccent,
            size: 28,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.brandAccent,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF66552C),
        border: Border.all(color: const Color(0xFFFFD400), width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Stai modificando una spesa esistente. Le modifiche saranno visibili a tutti i coinquilini.',
        style: TextStyle(color: Color(0xFFFFD400), fontSize: 16),
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
      padding: const EdgeInsets.fromLTRB(10, 6, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Importo',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.brandAccent,
              fontSize: 39,
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
      icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
      label: Text(
        _formatDate(date),
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF8C8990), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      style: const TextStyle(color: Colors.white, fontSize: 17),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2C2846),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF8C8990), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF8C8990), width: 2),
          borderRadius: BorderRadius.circular(8),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              const Divider(color: Color(0xFF807D7D), height: 10),
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
    final name = inquilino.nomeCompleto.isEmpty
        ? inquilino.nome
        : inquilino.nomeCompleto;
    final initials = _initials(name);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _avatarColor(initials),
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.brandPrimary,
            ),
            Text(
              _formatCurrency(share),
              style: const TextStyle(color: Colors.white, fontSize: 18),
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
                style: const TextStyle(color: Color(0xFFC1BFC8), fontSize: 20),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF9B98A0), fontSize: 13),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.brandPrimary,
        ),
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
      width: 240,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _fieldDecoration(
          borderColor: enabled
              ? const Color(0xFF8C8990)
              : const Color(0xFF5F596B),
          fillColor: enabled
              ? const Color(0xFF2C2846)
              : const Color(0xFF1D1A2E),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.contains(value) ? value : options.first,
            dropdownColor: const Color(0xFF3A3459),
            iconEnabledColor: enabled
                ? AppColors.brandAccent
                : const Color(0xFF6A5A86),
            iconDisabledColor: const Color(0xFF6A5A86),
            isExpanded: true,
            items: options
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        color: enabled
                            ? const Color(0xFFC1BFC8)
                            : const Color(0xFF77717F),
                        fontSize: 16,
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
    final names = data.quote
        .map((quota) => _quotaName(quota, data.inquilini))
        .where((name) => name.isNotEmpty)
        .toList();
    final share = data.quote.isEmpty
        ? data.spesa.importo
        : data.spesa.importo / data.quote.length;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB7B4BC)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Chi deve pagare',
            value: names.isEmpty ? 'Marco, Emilia' : names.join(', '),
          ),
          const Divider(color: Color(0xFF807D7D)),
          _SummaryRow(
            label: 'Quota per persone',
            value: _formatCurrency(share),
          ),
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
              color: Color(0xFFAFAEAE),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18)),
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
      constraints: const BoxConstraints(minHeight: 385),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFFF242E),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 19),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 66),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFAFAEAE),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 1.4),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        pillText,
                        style: TextStyle(color: color, fontSize: 13),
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
  Color fillColor = const Color(0xFF2C2846),
  Color borderColor = const Color(0xFF8C8990),
}) {
  return BoxDecoration(
    color: fillColor,
    border: Border.all(color: borderColor, width: 2),
    borderRadius: BorderRadius.circular(10),
  );
}

double _parseAmount(String value) {
  return double.tryParse(value.replaceAll(',', '.')) ?? 0;
}

String _quotaName(Quota quota, List<Inquilino> inquilini) {
  final id = quota.raw['inquilinoId'] ?? quota.raw['idInquilino'];
  if (id != null) {
    for (final inquilino in inquilini) {
      if (inquilino.id == id.toString()) {
        return inquilino.nomeCompleto.isEmpty
            ? inquilino.nome
            : inquilino.nomeCompleto;
      }
    }
  }
  return quota.raw['nome']?.toString() ?? '';
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
    Color(0xFF315173),
    Color(0xFFAAFFB5),
    Color(0xFFFFB58A),
    Color(0xFFEE7274),
  ];
  return colors[initials.codeUnitAt(0) % colors.length];
}

String _formatCurrency(double value) {
  return '€ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatLongDate(DateTime date) {
  const months = [
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
