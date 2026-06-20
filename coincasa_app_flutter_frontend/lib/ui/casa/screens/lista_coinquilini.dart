import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/domain/viewmodel/hub_casa_viewmodel.dart';
import 'package:coincasa_app/ui/casa/screens/condividi_codice.dart';
import 'package:coincasa_app/ui/casa/screens/elimina_coinquilino.dart'
    show showEliminaCoinquilinoDialog;

Inquilino? _resolveCurrentInquilino(List<Inquilino> coinquilini) {
  final me = ApiProvider.client;
  final currentId = me.currentUserId?.trim();
  if (currentId != null && currentId.isNotEmpty) {
    for (final c in coinquilini) {
      if (c.id.trim() == currentId) return c;
    }
  }
  final currentEmail = me.currentUserEmail?.trim().toLowerCase();
  if (currentEmail != null && currentEmail.isNotEmpty) {
    for (final c in coinquilini) {
      if (c.email.trim().toLowerCase() == currentEmail) return c;
    }
  }
  final currentDisplayName = me.currentUserDisplayName?.trim().toLowerCase();
  if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
    for (final c in coinquilini) {
      final values = [c.nomeCompleto, c.username]
          .map((v) => v.trim().toLowerCase());
      if (values.contains(currentDisplayName)) return c;
    }
  }
  return null;
}

class ListaCoinquiliniScreen extends ConsumerStatefulWidget {
  const ListaCoinquiliniScreen({super.key, required this.casaId});

  final String casaId;

  @override
  ConsumerState<ListaCoinquiliniScreen> createState() =>
      _ListaCoinquiliniScreenState();
}

class _ListaCoinquiliniScreenState
    extends ConsumerState<ListaCoinquiliniScreen> {
  Future<void> _promuovi(Inquilino inquilino) async {
    try {
      await ref
          .read(hubCasaViewModelProvider(widget.casaId).notifier)
          .updateRuoloInquilino(inquilino.id, {'ruolo': 'HomeAdmin'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${inquilino.username} promosso ad admin.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promozione non riuscita.')),
      );
    }
  }

  Future<void> _retrocedi(Inquilino inquilino) async {
    try {
      await ref
          .read(hubCasaViewModelProvider(widget.casaId).notifier)
          .updateRuoloInquilino(inquilino.id, {'ruolo': 'Inquilino'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${inquilino.username} retrocesso a membro.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retrocessione non riuscita.')),
      );
    }
  }

  Future<void> _rimuovi(Inquilino inquilino) async {
    try {
      await ref
          .read(hubCasaViewModelProvider(widget.casaId).notifier)
          .removeInquilino(inquilino.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${inquilino.username} rimosso.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rimozione non riuscita.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmAsync = ref.watch(hubCasaViewModelProvider(widget.casaId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: Navigator.of(context).pop,
        ),
        title: const Text(
          'Lista coinquilini',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(hubCasaViewModelProvider(widget.casaId)),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed('/account'),
              customBorder: const CircleBorder(),
              child: UserAvatar(
                radius: 20,
                userId: ApiProvider.client.currentUserAvatarSeed,
                username: ApiProvider.client.currentUserUsername,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: vmAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () =>
                ref.invalidate(hubCasaViewModelProvider(widget.casaId)),
          ),
          data: (state) {
            final coinquilini = state.inquilini;
            final currentUser = _resolveCurrentInquilino(coinquilini);
            final isAdmin = state.isAdmin;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${coinquilini.length} membri',
                    style: const TextStyle(
                      color: AppColors.brandPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowSoft,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: ListView.separated(
                        itemCount: coinquilini.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: AppColors.surfaceDarkMuted,
                          height: 32,
                          thickness: 1,
                        ),
                        itemBuilder: (context, index) {
                          final coinquilino = coinquilini[index];
                          final isSelf = coinquilino.id == currentUser?.id;
                          final showActions =
                              isAdmin && !coinquilino.isOwner && !isSelf;
                          return _CoinquilinoTile(
                            coinquilino: coinquilino,
                            showActions: showActions,
                            onPromuovi: coinquilino.isHomeAdmin
                                ? null
                                : () => _promuovi(coinquilino),
                            onRetrocedi: coinquilino.isHomeAdmin
                                ? () => _retrocedi(coinquilino)
                                : null,
                            onRimuovi: () {
                              showEliminaCoinquilinoDialog(
                                context,
                                nomeCoinquilino: coinquilino.username,
                                iniziali: resolveUserInitials(
                                  displayName: coinquilino.username,
                                ),
                                onRimuovi: () => _rimuovi(coinquilino),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    child: Center(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CondividiCodiceScreen(casaId: widget.casaId),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(280, 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
                          ),
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: AppColors.textOnDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Condividi codice invito',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 42),
          const SizedBox(height: 12),
          const Text('Non e possibile caricare i coinquilini.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}

class _CoinquilinoTile extends StatelessWidget {
  const _CoinquilinoTile({
    required this.coinquilino,
    required this.showActions,
    this.onPromuovi,
    this.onRetrocedi,
    this.onRimuovi,
  });

  final Inquilino coinquilino;
  final bool showActions;
  final VoidCallback? onPromuovi;
  final VoidCallback? onRetrocedi;
  final VoidCallback? onRimuovi;

  String get _roleLabel => coinquilino.isHomeAdmin ? 'Admin' : 'Inquilino';

  String get _joinDate {
    final date = coinquilino.dataIngresso;
    if (date == null) {
      return 'Data ingresso non disponibile';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'Dal $day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            radius: 28,
            userId: coinquilino.id,
            username: coinquilino.username,
            borderColor: coinquilino.isHomeAdmin
                ? AppColors.brandSecondary
                : null,
            borderWidth: coinquilino.isHomeAdmin ? 2 : 0,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coinquilino.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (coinquilino.nomeCompleto != coinquilino.username &&
                    coinquilino.nomeCompleto.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    coinquilino.nomeCompleto,
                    style: const TextStyle(
                      color: AppColors.textOnDarkMuted,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: 'Ruolo: ',
                    style: const TextStyle(
                      color: AppColors.textOnDarkMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: _roleLabel,
                        style: TextStyle(
                          color: coinquilino.isHomeAdmin
                              ? AppColors.featureAccent
                              : AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  coinquilino.email,
                  style: const TextStyle(
                    color: AppColors.textOnDarkMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _joinDate,
                  style: const TextStyle(
                    color: AppColors.textMutedDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          if (showActions)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (onPromuovi != null)
                  _ActionChip(
                    label: 'Promuovi',
                    color: AppColors.featureAccent,
                    onTap: onPromuovi,
                  ),
                if (onRetrocedi != null)
                  _ActionChip(
                    label: 'Retrocedi',
                    color: AppColors.lockOrange,
                    onTap: onRetrocedi,
                  ),
                const SizedBox(height: 8),
                _ActionChip(
                  label: 'Rimuovi',
                  color: AppColors.error,
                  onTap: onRimuovi,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.color, this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
