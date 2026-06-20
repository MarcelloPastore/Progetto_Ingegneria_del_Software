import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/app_outlined_button.dart';
import 'package:coincasa_app/core/widgets/common/delete_confirm_dialog.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/domain/viewmodel/problemi_viewmodel.dart';

class EliminaProblemaScreen extends ConsumerStatefulWidget {
  const EliminaProblemaScreen({super.key});

  static const String routeName = '/problemi/elimina';

  @override
  ConsumerState<EliminaProblemaScreen> createState() =>
      _EliminaProblemaScreenState();
}

class _EliminaProblemaScreenState extends ConsumerState<EliminaProblemaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (!mounted) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final problema = args is Problema ? args : null;

    if (problema == null) {
      Navigator.of(context).pop();
      return;
    }

    final currentUserId = ApiProvider.client.currentUserId?.trim() ?? '';
    final segnalatoDaId =
        problema.raw['segnalatoDaId']?.toString().trim() ?? '';
    final isCreator =
        currentUserId.isNotEmpty &&
        segnalatoDaId.isNotEmpty &&
        segnalatoDaId == currentUserId;
    final canDelete =
        ActiveCasaScope.of(context).isHomeAdmin || isCreator;

    if (!canDelete) {
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo l\'admin o chi ha segnalato il problema può eliminarlo.',
            ),
          ),
        );
      }
      return;
    }

    final casaId = ActiveCasaScope.read(context).selectedCasaId ?? '';
    await showDeleteConfirmDialog(
      context: context,
      title: 'Eliminare il problema?',
      description:
          '"${problema.titolo}" verrà rimosso definitivamente. Tutti i coinquilini verranno avvisati.',
      onConfirm: () => ref
          .read(problemiViewModelProvider(casaId).notifier)
          .deleteProblema(problema.id),
      onSuccess: () =>
          Navigator.of(context).pushReplacementNamed('/problemi'),
    );

    // Dialog chiuso senza conferma — torna indietro
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppColors.darkBackground);
  }
}

// ---------------------------------------------------------------------------
// Schermata "non autorizzato" (accessibile come route separata se necessario)
// ---------------------------------------------------------------------------

class EliminaProblemaUnauthorizedScreen extends StatelessWidget {
  const EliminaProblemaUnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        bottomNavigationBar: const HouseQuickNav(currentRoute: '/problemi'),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: AppColors.brandAccent,
                    size: 56,
                  ),
                  const SizedBox(height: AppSizes.p20),
                  const Text(
                    'Non autorizzato',
                    style: AppTextStyles.screenTitleStrong,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  const Text(
                    'Solo l\'admin o chi ha segnalato il problema può eliminarlo.',
                    style: AppTextStyles.bodyMutedRelaxed,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.p32),
                  AppOutlinedButton(
                    label: 'Torna ai problemi',
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/problemi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
