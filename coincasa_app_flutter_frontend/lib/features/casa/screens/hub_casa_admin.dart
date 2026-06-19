import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/domain/viewmodel/dashboard_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/hub_casa_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/features/casa/screens/archivio_documenti_vuoto.dart';
import 'package:coincasa_app/features/casa/screens/condividi_codice.dart';
import 'package:coincasa_app/features/casa/screens/elimina_casa.dart';
import 'package:coincasa_app/features/casa/screens/lista_case.dart';
import 'package:coincasa_app/features/casa/screens/lista_coinquilini.dart';
import 'package:coincasa_app/features/casa/screens/lascia_casa.dart';
import 'package:coincasa_app/features/casa/screens/modifica_casa.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';

class HubCasaAdminScreen extends ConsumerStatefulWidget {
  const HubCasaAdminScreen({super.key, required this.casaId});

  final String casaId;

  @override
  ConsumerState<HubCasaAdminScreen> createState() => _HubCasaAdminScreenState();
}

class _HubCasaAdminScreenState extends ConsumerState<HubCasaAdminScreen> {
  Future<void> _deleteCasa(HubCasaState state) async {
    final confirmed = await showEliminaCasaDialog(
      context,
      nomeCasa: state.casa.nome,
      speseCount: state.speseNonSaldateCount,
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(hubCasaViewModelProvider(widget.casaId).notifier)
          .deleteCasa();
      ref.invalidate(listaCaseViewModelProvider);
      ref.invalidate(dashboardViewModelProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ListaCaseScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eliminazione casa non riuscita.')),
      );
    }
  }

  Future<void> _leaveCasa(HubCasaState state) async {
    final confirmed = await showLasciaCasaDialog(
      context,
      nomeCasa: state.casa.nome,
    );
    if (confirmed != true) return;

    final currentId = ApiProvider.client.currentUserId?.trim() ?? '';
    final currentInquilino = _resolveCurrentInquilino(state.inquilini);

    if (currentInquilino == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile identificare l\'utente.')),
      );
      return;
    }

    try {
      await ref
          .read(hubCasaViewModelProvider(widget.casaId).notifier)
          .lasciaCasa(currentInquilino.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uscita dalla casa non riuscita.')),
      );
      return;
    }
    ref.invalidate(listaCaseViewModelProvider);
    ref.invalidate(dashboardViewModelProvider);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LasciaCasaSuccessScreen(
          nomeCasa: state.casa.nome,
          spesePendenti: state.spesePendentiPer(currentId),
        ),
      ),
    );
  }

  Inquilino? _resolveCurrentInquilino(List<Inquilino> coinquilini) {
    final currentId = ApiProvider.client.currentUserId?.trim();
    if (currentId != null && currentId.isNotEmpty) {
      for (final i in coinquilini) {
        if (i.id.trim() == currentId) return i;
      }
    }
    final currentEmail =
        ApiProvider.client.currentUserEmail?.trim().toLowerCase();
    if (currentEmail != null && currentEmail.isNotEmpty) {
      for (final i in coinquilini) {
        if (i.email.trim().toLowerCase() == currentEmail) return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vmAsync = ref.watch(hubCasaViewModelProvider(widget.casaId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.brandPrimaryDark,
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Hub Casa',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/account'),
              child: UserAvatar(
                radius: 18,
                userId: ApiProvider.client.currentUserAvatarSeed,
                username: ApiProvider.client.currentUserUsername,
                displayName: ApiProvider.client.currentUserDisplayName,
                showPresenceDot: true,
                presenceDotColor: AppColors.statusNegative,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: vmAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 44),
                const SizedBox(height: 12),
                const Text('Non è possibile caricare i dati della casa.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(hubCasaViewModelProvider(widget.casaId)),
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
          data: (state) {
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(hubCasaViewModelProvider(widget.casaId)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                children: [
                  _HouseHeaderCard(state: state),
                  const SizedBox(height: 24),
                  Text(
                    'Gestione',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ManagementAction(
                    iconData: Icons.group_outlined,
                    iconColor: AppColors.statusInfo,
                    title: 'Coinquilini e ruoli',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ListaCoinquiliniScreen(casaId: state.casa.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.isAdmin) ...[
                    _ManagementAction(
                      iconData: Icons.share_outlined,
                      iconColor: AppColors.lockOrange,
                      title: 'Condividi link invito',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CondividiCodiceScreen(casaId: state.casa.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ManagementAction(
                      iconData: Icons.edit_outlined,
                      iconColor: AppColors.featureAccent,
                      title: 'Modifica informazioni casa',
                      onTap: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => ModificaCasaScreen(
                              casaId: state.casa.id,
                              name: state.casa.nome,
                              city: state.casa.citta,
                              address: state.casa.indirizzo,
                              type: state.casa.tipoCasa,
                            ),
                          ),
                        );
                        if (updated == true) {
                          ref.invalidate(hubCasaViewModelProvider(widget.casaId));
                          ref.invalidate(listaCaseViewModelProvider);
                          ref.invalidate(dashboardViewModelProvider);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ManagementAction(
                    iconData: Icons.folder_open,
                    iconColor: AppColors.statusNegative,
                    title: 'Documenti condivisi',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ArchivioDocumentiVuotoScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ManagementAction(
                    iconData: Icons.list_alt_rounded,
                    iconColor: AppColors.statusPositive,
                    title: 'Lista case',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ListaCaseScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DeleteHouseButton(
                    isOwner: state.isCurrentUserOwner || state.isAdmin,
                    onPressed: (state.isCurrentUserOwner || state.isAdmin)
                        ? () => _deleteCasa(state)
                        : () => _leaveCasa(state),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
    );
  }
}

class _HouseHeaderCard extends StatelessWidget {
  const _HouseHeaderCard({required this.state});

  final HubCasaState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOverlay,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/Icons/casa_colorata.png',
                width: 70,
                height: 70,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.casa.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.casa.tipoCasa.isEmpty
                          ? 'Appartamento'
                          : state.casa.tipoCasa,
                      style: const TextStyle(
                        color: AppColors.textOnDarkMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.brandPrimaryDark,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatisticChip(
                value: '${state.inquilini.length}',
                label: 'Membri',
                valueColor: AppColors.featureAccent,
              ),
              _StatisticChip(
                value: '${state.speseCount}',
                label: 'Spese',
                valueColor: AppColors.statusPositive,
              ),
              _StatisticChip(
                value: '${state.scadenzeCount}',
                label: 'Scadenze',
                valueColor: AppColors.warningSoft,
              ),
              _StatisticChip(
                value: '${state.problemiCount}',
                label: 'Problemi',
                valueColor: AppColors.statusInfo,
              ),
              _StatisticChip(
                value: '${state.turniCount}',
                label: 'Turni',
                valueColor: AppColors.brandAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticChip extends StatelessWidget {
  const _StatisticChip({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ManagementAction extends StatelessWidget {
  const _ManagementAction({
    required this.iconData,
    required this.iconColor,
    required this.title,
    this.onTap,
  });

  final IconData iconData;
  final Color iconColor;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDarkMuted,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(iconData, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteHouseButton extends StatelessWidget {
  const _DeleteHouseButton({required this.onPressed, required this.isOwner});

  final VoidCallback onPressed;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final label = isOwner ? 'Elimina la casa' : 'Lascia la casa';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.errorContainerDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusNegative, width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                color: AppColors.statusNegative,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.statusNegative,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
