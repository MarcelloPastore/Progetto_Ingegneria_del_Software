import 'package:flutter/material.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/core/utils/user_initials.dart';
import 'package:coincasa_app/features/casa/screens/condividi_codice.dart';
import 'package:coincasa_app/features/casa/screens/elimina_coinquilino.dart'
    show showEliminaCoinquilinoDialog;

// Riferimento globale per il file all'utente corrente per facilitare l'accesso alle variabili di sessione
final _me = ApiProvider.client;

Inquilino? _resolveCurrentInquilino(List<Inquilino> coinquilini) {
  final currentId = _me.currentUserId?.trim();
  if (currentId != null && currentId.isNotEmpty) {
    for (final coinquilino in coinquilini) {
      if (coinquilino.id.trim() == currentId) {
        return coinquilino;
      }
    }
  }

  final currentEmail = _me.currentUserEmail?.trim().toLowerCase();
  if (currentEmail != null && currentEmail.isNotEmpty) {
    for (final coinquilino in coinquilini) {
      if (coinquilino.email.trim().toLowerCase() == currentEmail) {
        return coinquilino;
      }
    }
  }

  final currentDisplayName = _me.currentUserDisplayName?.trim().toLowerCase();
  if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
    for (final coinquilino in coinquilini) {
      final values = [
        coinquilino.nomeCompleto,
        coinquilino.username,
      ].map((value) => value.trim().toLowerCase());
      if (values.contains(currentDisplayName)) {
        return coinquilino;
      }
    }
  }

  return null;
}

class ListaCoinquiliniScreen extends StatefulWidget {
  const ListaCoinquiliniScreen({super.key, required this.casaId});

  final String casaId;

  @override
  State<ListaCoinquiliniScreen> createState() => _ListaCoinquiliniScreenState();
}

class _ListaCoinquiliniScreenState extends State<ListaCoinquiliniScreen> {
  late Future<List<Inquilino>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Inquilino>> _load() async {
    final coinquilini = await ApiProvider.casa.listInquilini(widget.casaId);
    final current = _resolveCurrentInquilino(coinquilini);
    if (current != null) {
      _me.setCurrentUserIdentity(
        id: current.id,
        email: current.email,
        name: current.nome,
        surname: current.cognome,
        displayName: current.nomeCompleto,
        username: current.username,
      );
    }
    return coinquilini;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _promuovi(Inquilino inquilino) async {
    try {
      await ApiProvider.casa.updateRuolo(widget.casaId, inquilino.id, {
        'ruolo': 'HomeAdmin',
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${inquilino.username} promosso ad admin.')),
      );
      _reload();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Promozione non riuscita.')));
    }
  }

  Future<void> _retrocedi(Inquilino inquilino) async {
    try {
      await ApiProvider.casa.updateRuolo(widget.casaId, inquilino.id, {
        'ruolo': 'Inquilino',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${inquilino.username} retrocesso a membro.')),
      );
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retrocessione non riuscita.')),
      );
    }
  }

  Future<void> _rimuovi(Inquilino inquilino) async {
    try {
      await ApiProvider.casa.removeInquilino(widget.casaId, inquilino.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${inquilino.username} rimosso.')),
      );
      _reload();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rimozione non riuscita.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CurrentUserAvatar(future: _future),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Inquilino>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _reload);
            }

            final coinquilini = snapshot.data ?? const [];
            final currentUser = _resolveCurrentInquilino(coinquilini);
            final isAdmin = currentUser?.isHomeAdmin ?? false;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${coinquilini.length} membri',
                    style: const TextStyle(
                      color: Color(0xFF4B2ED9),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1947),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x15000000),
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
                          color: Color(0xFF2A2E51),
                          height: 32,
                          thickness: 1,
                        ),
                        itemBuilder: (context, index) {
                          final coinquilino = coinquilini[index];
                          final isSelf = coinquilino.id == currentUser?.id;
                          // L'owner non può mai essere retrocesso o rimosso.
                          // I pulsanti sono visibili solo a un admin, su membri non-owner e diversi da sé.
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
                        backgroundColor: const Color(0xFF5A3AE0),
                        foregroundColor: Colors.white,
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

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar({required this.future});

  final Future<List<Inquilino>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Inquilino>>(
      future: future,
      builder: (context, snapshot) {
        final current = snapshot.hasData
            ? _resolveCurrentInquilino(snapshot.data!)
            : null;

        return UserAvatar(
          radius: 20,
          userId: current?.id ?? _me.currentUserAvatarSeed,
          username: current?.username ?? _me.currentUserUsername,
        );
      },
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

  String get _roleLabel => coinquilino.isHomeAdmin ? 'Admin' : 'Membro';

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
                ? const Color.fromARGB(255, 125, 86, 209)
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
                      color: Color(0xFFB8B8D5),
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
                      color: Color(0xFFB8B8D5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: _roleLabel,
                        style: TextStyle(
                          color: coinquilino.isHomeAdmin
                              ? const Color(0xFF7E5BF6)
                              : Colors.white,
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
                    color: Color(0xFFB8B8D5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _joinDate,
                  style: const TextStyle(
                    color: Color(0xFF7A7D96),
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
                    color: const Color(0xFF6D5FFF),
                    onTap: onPromuovi,
                  ),
                if (onRetrocedi != null)
                  _ActionChip(
                    label: 'Retrocedi',
                    color: const Color(0xFFE08A00),
                    onTap: onRetrocedi,
                  ),
                const SizedBox(height: 8),
                _ActionChip(
                  label: 'Rimuovi',
                  color: const Color(0xFFD12C3D),
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
