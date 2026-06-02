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
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/features/spese/screens/modifiche_spese_negata.dart';

class EliminaSpesaScreen extends ConsumerStatefulWidget {
  const EliminaSpesaScreen({super.key});

  static const String routeName = '/spese/elimina';

  @override
  ConsumerState<EliminaSpesaScreen> createState() => _EliminaSpesaScreenState();
}

class _EliminaSpesaScreenState extends ConsumerState<EliminaSpesaScreen> {
  late Future<_DeleteData?> _future;
  bool _initialized = false;
  bool _deleting = false;
  _DeleteState _state = _DeleteState.confirm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _future = _loadData();
  }

  Future<_DeleteData?> _loadData() async {
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
      ApiProvider.spese
          .getQuote(casa.id, spesaId)
          .catchError((_) => const <Quota>[]),
      ApiProvider.casa
          .listInquilini(casa.id)
          .catchError((_) => const <Inquilino>[]),
    ]);
    return _DeleteData(
      casa: casa,
      spesa: results[0] as Spesa,
      quote: results[1] as List<Quota>,
      inquilini: results[2] as List<Inquilino>,
    );
  }

  Future<void> _delete(_DeleteData data) async {
    if (_deleting) {
      return;
    }
    if (data.quote.any((quota) => quota.pagata)) {
      setState(() => _state = _DeleteState.denied);
      return;
    }
    setState(() => _deleting = true);
    try {
      await ApiProvider.spese.delete(data.casa.id, data.spesa.id);
      if (mounted) {
        setState(() => _state = _DeleteState.success);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = _DeleteState.denied);
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6F6C78),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/spese'),
      body: SafeArea(
        child: FutureBuilder<_DeleteData?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('Spesa non disponibile.'));
            }
            return _DeleteContent(
              data: data,
              state: _state,
              deleting: _deleting,
              onDelete: () => _delete(data),
              onCancel: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
    );
  }
}

class _DeleteContent extends StatelessWidget {
  const _DeleteContent({
    required this.data,
    required this.state,
    required this.deleting,
    required this.onDelete,
    required this.onCancel,
  });

  final _DeleteData data;
  final _DeleteState state;
  final bool deleting;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BackTitle(title: 'Dettaglio spesa', onBack: onCancel),
              const SizedBox(height: 50),
              Text(
                _formatCurrency(data.spesa.importo),
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitleStrong.copyWith(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.spesa.descrizione} - ${_formatLongDate(data.spesa.data)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC1BFC8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              _Summary(data: data),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state == _DeleteState.success
                          ? null
                          : () => Navigator.of(context).pushReplacementNamed(
                              ModificheSpeseNegataScreen.routeName,
                              arguments: data.spesa.id,
                            ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.brandAccent,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius16,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Modifica spesa',
                        style: TextStyle(
                          color: AppColors.brandAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state == _DeleteState.confirm
                          ? onDelete
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFF7A7E),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius16,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Elimina spesa',
                        style: TextStyle(
                          color: Color(0xFFFF7A7E),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(ListaSpeseAdminScreen.routeName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF668FD4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                  ),
                ),
                child: const Text(
                  'Torna alle spese',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 82,
          child: switch (state) {
            _DeleteState.confirm => _ConfirmDeleteCard(
              data: data,
              deleting: deleting,
              onDelete: onDelete,
              onCancel: onCancel,
            ),
            _DeleteState.success => _DeleteSuccessCard(data: data),
            _DeleteState.denied => _DeleteDeniedCard(onClose: onCancel),
          },
        ),
      ],
    );
  }
}

class _ConfirmDeleteCard extends StatelessWidget {
  const _ConfirmDeleteCard({
    required this.data,
    required this.deleting,
    required this.onDelete,
    required this.onCancel,
  });

  final _DeleteData data;
  final bool deleting;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(38, 18, 38, 30),
      decoration: _cardDecoration(const Color(0xFF2D293B)),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 29,
            backgroundColor: Color(0xFFFF7075),
            child: Icon(Icons.delete, color: Color(0xFF5A141D), size: 34),
          ),
          const SizedBox(height: 18),
          const Text(
            'Eliminare la spesa?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${data.spesa.descrizione} - ${_formatCurrency(data.spesa.importo)} verrà rimossa definitivamente dalla lista.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC1BFC8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          _DangerButton(
            label: deleting ? 'Eliminazione...' : 'Sì, elimina definitivamente',
            onPressed: deleting ? null : onDelete,
          ),
          const SizedBox(height: 10),
          _PurpleOutlineButton(label: 'Annulla', onPressed: onCancel),
        ],
      ),
    );
  }
}

class _DeleteSuccessCard extends StatelessWidget {
  const _DeleteSuccessCard({required this.data});

  final _DeleteData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 374),
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 30),
      decoration: _cardDecoration(const Color(0xFF45FF58)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✓', style: TextStyle(fontSize: 100, height: 1)),
          const SizedBox(height: 10),
          const Text(
            'Spesa eliminata',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'La spesa “${data.spesa.descrizione}” è stata eliminata con successo.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC1BFC8),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 56),
          _PurpleOutlineButton(
            label: 'Torna alle spese',
            onPressed: () => Navigator.of(
              context,
            ).pushReplacementNamed(ListaSpeseAdminScreen.routeName),
          ),
        ],
      ),
    );
  }
}

class _DeleteDeniedCard extends StatelessWidget {
  const _DeleteDeniedCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 460),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      decoration: _cardDecoration(const Color(0xFFFF1721)),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFFF242E),
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white, size: 19),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, color: Color(0xFFFF1721), size: 72),
                const SizedBox(height: 28),
                const Text(
                  'Impossibile eliminare la spesa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Questa spesa ha quote già pagate da uno o più coinquilini. Non è possibile eliminarla per non perdere i pagamenti già registrati.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC1BFC8),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF25A7FF),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Color(0xFFFF1721), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Spesa protetta da pagamenti esistenti',
                        style: TextStyle(
                          color: Color(0xFFFF1721),
                          fontSize: 13,
                        ),
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

class _Summary extends StatelessWidget {
  const _Summary({required this.data});

  final _DeleteData data;

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
        border: Border.all(color: const Color(0xFFC1BFC8), width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Chi deve pagare',
            value: names.isEmpty ? 'Marco, Emilia' : names.join(', '),
          ),
          const Divider(color: Color(0xFFB8B5C1)),
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
              color: Color(0xFFC1BFC8),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
        const SizedBox(width: 6),
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

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF3B44), width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF3B44),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PurpleOutlineButton extends StatelessWidget {
  const _PurpleOutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.brandPrimary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.brandPrimary,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DeleteData {
  const _DeleteData({
    required this.casa,
    required this.spesa,
    required this.quote,
    required this.inquilini,
  });

  final Casa casa;
  final Spesa spesa;
  final List<Quota> quote;
  final List<Inquilino> inquilini;
}

enum _DeleteState { confirm, success, denied }

BoxDecoration _cardDecoration(Color borderColor) {
  return BoxDecoration(
    color: AppColors.darkBackground,
    border: Border.all(color: borderColor, width: 2),
    borderRadius: BorderRadius.circular(10),
    boxShadow: const [
      BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(0, 3)),
    ],
  );
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

String _formatCurrency(double value) {
  return '€${value.toStringAsFixed(2).replaceAll('.', ',')}';
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
