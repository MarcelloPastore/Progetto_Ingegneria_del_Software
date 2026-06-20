import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/utils/formatters.dart';
import 'package:coincasa_app/core/widgets/common/app_outlined_button.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/screen_back_header.dart';
import 'package:coincasa_app/features/spese/screens/lista_spese_admin.dart';
import 'package:coincasa_app/features/spese/screens/modifiche_spese_negata.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';

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
    final caseUtente = await ref.read(listaCaseViewModelProvider.future);
    if (caseUtente.isEmpty) {
      return null;
    }
    final casa = activeCasaController.resolveCasa(caseUtente);
    final speseState = await ref.read(speseViewModelProvider(casa.id).future);
    final notifier = ref.read(speseViewModelProvider(casa.id).notifier);
    final results = await Future.wait<dynamic>([
      args is Spesa
          ? Future<Spesa>.value(args)
          : notifier.getSpesaById(spesaId),
      notifier.getQuoteSpesa(spesaId).catchError((_) => const <Quota>[]),
    ]);
    return _DeleteData(
      casa: casa,
      spesa: results[0] as Spesa,
      quote: results[1] as List<Quota>,
      inquilini: speseState.inquilini,
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
      await ref
          .read(speseViewModelProvider(data.casa.id).notifier)
          .deleteSpesa(data.spesa.id);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p20,
            AppSizes.p24,
            AppSizes.p20,
            AppSizes.p28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenBackHeader(title: 'Dettaglio spesa', onBack: onCancel),
              const SizedBox(height: AppSizes.p50),
              Text(
                formatCurrency(data.spesa.importo),
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitleStrong.copyWith(
                  fontSize: AppSizes.p40,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              Text(
                '${data.spesa.descrizione} - ${formatLongDate(data.spesa.data)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: AppSizes.p18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.p28),
              _Summary(data: data),
              const SizedBox(height: AppSizes.p32),
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
                          width: AppSizes.p2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.p17,
                        ),
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
                          fontSize: AppSizes.p17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.p16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state == _DeleteState.confirm
                          ? onDelete
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.statusNegative,
                          width: AppSizes.p2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.p17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radius16,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Elimina spesa',
                        style: TextStyle(
                          color: AppColors.statusNegative,
                          fontSize: AppSizes.p17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p18),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(ListaSpeseAdminScreen.routeName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusInfo,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                  ),
                ),
                child: const Text(
                  'Torna alle spese',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: AppSizes.p23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: AppSizes.p20,
          right: AppSizes.p20,
          top: AppSizes.p82,
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
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p38,
        AppSizes.p18,
        AppSizes.p38,
        AppSizes.p30,
      ),
      decoration: _cardDecoration(AppColors.surfaceDarkMuted),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 29,
            backgroundColor: AppColors.statusNegative,
            child: Icon(
              Icons.delete,
              color: AppColors.errorContainerStrong,
              size: AppSizes.p34,
            ),
          ),
          const SizedBox(height: AppSizes.p18),
          const Text(
            'Eliminare la spesa?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p14),
          Text(
            '${data.spesa.descrizione} - ${formatCurrency(data.spesa.importo)} verrà rimossa definitivamente dalla lista.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: AppSizes.p18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.p26),
          AppOutlinedButton(
            label: 'Sì, elimina definitivamente',
            onPressed: onDelete,
            color: AppColors.errorStrong,
            isLoading: deleting,
          ),
          const SizedBox(height: AppSizes.p10),
          AppOutlinedButton(label: 'Annulla', onPressed: onCancel),
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
      constraints: const BoxConstraints(minHeight: AppSizes.p374),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p26,
        AppSizes.p18,
        AppSizes.p26,
        AppSizes.p30,
      ),
      decoration: _cardDecoration(AppColors.statusPositive),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '✓',
            style: TextStyle(fontSize: AppSizes.p100, height: AppSizes.p1),
          ),
          const SizedBox(height: AppSizes.p10),
          const Text(
            'Spesa eliminata',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p10),
          Text(
            'La spesa “${data.spesa.descrizione}” è stata eliminata con successo.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: AppSizes.p18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.p56),
          AppOutlinedButton(
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
      constraints: const BoxConstraints(minHeight: AppSizes.p460),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p22,
        AppSizes.p16,
        AppSizes.p22,
        AppSizes.p28,
      ),
      decoration: _cardDecoration(AppColors.errorStrong),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.errorStrong,
              child: IconButton(
                onPressed: onClose,
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
                const Icon(
                  Icons.block,
                  color: AppColors.errorStrong,
                  size: AppSizes.p72,
                ),
                const SizedBox(height: AppSizes.p28),
                const Text(
                  'Impossibile eliminare la spesa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: AppSizes.p20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSizes.p12),
                const Text(
                  'Questa spesa ha quote già pagate da uno o più coinquilini. Non è possibile eliminarla per non perdere i pagamenti già registrati.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: AppSizes.p18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.p30),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p16,
                    vertical: AppSizes.p8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.statusInfo,
                      width: AppSizes.p3,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radius30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        color: AppColors.errorStrong,
                        size: AppSizes.p18,
                      ),
                      SizedBox(width: AppSizes.p8),
                      Text(
                        'Spesa protetta da pagamenti esistenti',
                        style: TextStyle(
                          color: AppColors.errorStrong,
                          fontSize: AppSizes.p13,
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
        border: Border.all(color: AppColors.textDisabled, width: AppSizes.p1_2),
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p18,
        AppSizes.p14,
        AppSizes.p18,
        AppSizes.p14,
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Chi deve pagare',
            value: names.isEmpty ? 'Nessuno' : names.join(', '),
          ),
          const Divider(color: AppColors.textMutedSoft),
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
              color: AppColors.textDisabled,
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
    border: Border.all(color: borderColor, width: AppSizes.p2),
    borderRadius: BorderRadius.circular(AppSizes.radius10),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadowMedium,
        blurRadius: AppSizes.p5,
        offset: Offset(0, 3),
      ),
    ],
  );
}
