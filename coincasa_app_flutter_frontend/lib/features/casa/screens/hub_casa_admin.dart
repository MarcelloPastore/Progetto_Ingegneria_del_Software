import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/utils/jwt_utils.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/casa/screens/archivio_documenti_vuoto.dart';
import 'package:coincasa_app/features/casa/screens/condividi_codice.dart';
import 'package:coincasa_app/features/casa/screens/elimina_casa.dart';
import 'package:coincasa_app/features/casa/screens/lista_case.dart';
import 'package:coincasa_app/features/casa/screens/lista_coinquilini.dart';
import 'package:coincasa_app/features/casa/screens/lascia_casa.dart';
import 'package:coincasa_app/features/casa/screens/modifica_casa.dart';

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

bool _isOwnerById(List<Inquilino> inquilini) {
  final token = _me.authToken;
  final jwtId = token != null ? JwtUtils.extractUserId(token)?.trim() : null;
  final currentId = (jwtId?.isNotEmpty == true
      ? jwtId
      : _me.currentUserId?.trim());
  if (currentId == null || currentId.isEmpty) return false;
  try {
    final owner = inquilini.firstWhere((i) => i.isOwner);
    return owner.id.trim() == currentId;
  } catch (_) {
    return false;
  }
}

class HubCasaAdminScreen extends StatefulWidget {
  const HubCasaAdminScreen({super.key, required this.casaId});

  final String casaId;

  @override
  State<HubCasaAdminScreen> createState() => _HubCasaAdminScreenState();
}

class _HubCasaAdminScreenState extends State<HubCasaAdminScreen> {
  late Future<_HubCasaData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HubCasaData> _load() async {
    final hub = await ApiProvider.casa.getHub(widget.casaId);

    final casaJson = hub['casa'] as Map<String, dynamic>;
    final casa = Casa.fromJson(casaJson);

    final membriJson = casaJson['membri'];
    final inquilini = (membriJson is List)
        ? membriJson
              .cast<Map<String, dynamic>>()
              .map(Inquilino.fromJson)
              .toList()
        : <Inquilino>[];

    final current = _resolveCurrentInquilino(inquilini);
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

    final ruolo = hub['ruolo']?.toString() ?? '';
    final isAdmin = ruolo == 'HomeAdmin' || ruolo == 'SysAdmin';

    final isOwnerFromHub =
        hub['isOwner'] as bool? ?? hub['isCurrentUserOwner'] as bool?;
    final isCurrentUserOwner =
        isOwnerFromHub ?? current?.isOwner ?? _isOwnerById(inquilini);

    // Recupera le spese per la logica di eliminazione/uscita dalla casa
    final spese = await ApiProvider.spese.list(widget.casaId);

    return _HubCasaData(
      casa: casa,
      inquilini: inquilini,
      speseCount: hub['speseCount'] as int? ?? 0,
      scadenzeCount: hub['scadenzeCount'] as int? ?? 0,
      problemiCount: hub['problemiCount'] as int? ?? 0,
      turniCount: hub['turniCount'] as int? ?? 0,
      spese: spese,
      isAdmin: isAdmin,
      isCurrentUserOwner: isCurrentUserOwner,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _navigateToModificaCasa(_HubCasaData data) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ModificaCasaScreen(
          casaId: data.casa.id,
          name: data.casa.nome,
          city: data.casa.citta,
          address: data.casa.indirizzo,
          type: data.casa.tipoCasa,
        ),
      ),
    );
    if (result == true) _reload();
  }

  Future<void> _deleteCasa(_HubCasaData data) async {
    // Conta le spese con almeno una quota esplicitamente non pagata.
    // Spese con tutte le quote saldate (o senza partecipanti) non vengono conteggiate.
    final speseNonSaldate = data.spese.where((s) {
      if (s.partecipanti.isEmpty) return false;
      return s.partecipanti.any((q) {
        final raw = q['pagata'] ?? q['pagato'] ?? q['isPaid'];
        final pagata = raw == true || raw?.toString().toLowerCase() == 'true';
        return !pagata;
      });
    }).length;

    final confirmed = await showEliminaCasaDialog(
      context,
      nomeCasa: data.casa.nome,
      speseCount: speseNonSaldate,
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ApiProvider.casa.delete(data.casa.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ListaCaseScreen()),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eliminazione casa non riuscita.')),
      );
    }
  }

  Future<void> _leaveCasa(_HubCasaData data) async {
    final confirmed = await showLasciaCasaDialog(
      context,
      nomeCasa: data.casa.nome,
    );
    if (confirmed != true) return;

    // Filtra le spese in cui l'utente corrente ha almeno una quota esplicitamente non pagata.
    final currentId = _me.currentUserId?.trim() ?? '';
    final spesePendenti = data.spese.where((spesa) {
      if (spesa.partecipanti.isEmpty) return false;
      return spesa.partecipanti.any((q) {
        final uid =
            (q['utenteId'] ??
                    q['idUtente'] ??
                    q['inquilinoId'] ??
                    (q['utente'] as Map?)?['id'])
                ?.toString()
                .trim() ??
            '';
        final raw = q['pagata'] ?? q['pagato'] ?? q['isPaid'];
        final pagata = raw == true || raw?.toString().toLowerCase() == 'true';
        return uid == currentId && !pagata;
      });
    }).toList();

    final currentInquilino = _resolveCurrentInquilino(data.inquilini);
    if (currentInquilino == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile identificare l\'utente.')),
      );
      return;
    }

    try {
      await ApiProvider.casa.removeInquilino(data.casa.id, currentInquilino.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uscita dalla casa non riuscita.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LasciaCasaSuccessScreen(
          nomeCasa: data.casa.nome,
          spesePendenti: spesePendenti,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.brandPrimary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const ListaCaseScreen()),
          ),
        ),
        title: const Text(
          'Hub Casa',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed('/account'),
              customBorder: const CircleBorder(),
              child: _CurrentUserAvatar(future: _future),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_HubCasaData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _HubErrorState(onRetry: _reload);
            }

            final data = snapshot.data!;
            final isCurrentOwner = data.isCurrentUserOwner;
            final isAdmin = data.isAdmin;

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                children: [
                  _HouseHeaderCard(data: data, isAdmin: isAdmin),
                  const SizedBox(height: 20),
                  _ManagementSection(
                    data: data,
                    isAdmin: isAdmin,
                    onModificaCasa: () => _navigateToModificaCasa(data),
                  ),
                  const SizedBox(height: 20),
                  if (!isAdmin) const _AdminWarningCard(),
                  if (!isAdmin) const SizedBox(height: 16),
                  _DeleteHouseButton(
                    isOwner: isCurrentOwner || isAdmin,
                    onPressed: (isCurrentOwner || isAdmin)
                        ? () => _deleteCasa(data)
                        : () => _leaveCasa(data),
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

class _HubCasaData {
  const _HubCasaData({
    required this.casa,
    required this.inquilini,
    required this.speseCount,
    required this.scadenzeCount,
    required this.problemiCount,
    required this.turniCount,
    required this.spese,
    required this.isAdmin,
    required this.isCurrentUserOwner,
  });

  final Casa casa;
  final List<Inquilino> inquilini;
  final int speseCount;
  final int scadenzeCount;
  final int problemiCount;
  final int turniCount;
  final List<Spesa> spese;
  final bool isAdmin;
  final bool isCurrentUserOwner;
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar({required this.future});

  final Future<_HubCasaData> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HubCasaData>(
      future: future,
      builder: (context, snapshot) {
        final current = snapshot.hasData
            ? _resolveCurrentInquilino(snapshot.data!.inquilini)
            : null;

        return UserAvatar(
          radius: 18,
          userId: current?.id ?? _me.currentUserAvatarSeed,
          username: current?.username ?? _me.currentUserUsername,
        );
      },
    );
  }
}

class _HubErrorState extends StatelessWidget {
  const _HubErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 44),
            const SizedBox(height: 12),
            const Text('Non e possibile caricare i dati della casa.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Riprova')),
          ],
        ),
      ),
    );
  }
}

class _HouseHeaderCard extends StatelessWidget {
  const _HouseHeaderCard({required this.data, required this.isAdmin});

  final _HubCasaData data;
  final bool isAdmin;

  String get _address {
    final parts = [
      data.casa.indirizzo,
      data.casa.citta,
    ].where((part) => part.trim().isNotEmpty).join(' - ');
    return '${data.casa.tipoCasa.isEmpty ? 'Casa' : data.casa.tipoCasa} - $parts';
  }

  String get _roleLabel => isAdmin ? 'Admin' : 'Inquilino';

  Inquilino? get _owner {
    try {
      return data.inquilini.firstWhere((i) => i.isOwner);
    } catch (_) {
      return data.inquilini.isNotEmpty ? data.inquilini.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkElevated,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D254E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/Icons/casa_colorata.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.casa.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _address,
                      style: const TextStyle(
                        color: Color(0xFFB6B6D2),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5E6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _roleLabel,
                  style: TextStyle(
                    color: Color(0xFF2A5FA8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatisticChip(
                  value: '${data.inquilini.length}',
                  label: 'Membri',
                  valueColor: const Color(0xFF9B5BFF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(
                  value: '${data.speseCount}',
                  label: 'Spese',
                  valueColor: const Color(0xFF53D86A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(
                  value: '${data.scadenzeCount}',
                  label: 'Scadenze',
                  valueColor: const Color(0xFFF9A825),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(
                  value: '${data.problemiCount}',
                  label: 'Problemi',
                  valueColor: const Color(0xFF2F9BFF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(
                  value: '${data.turniCount}',
                  label: 'Turni',
                  valueColor: const Color(0xFFB15CFF),
                ),
              ),
            ],
          ),

          // ── Owner row ────────────────────────────────────────────────
          if (_owner != null) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF2A2F52), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Proprietario',
                  style: TextStyle(
                    color: Color(0xFF8A8AB0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                UserAvatar(
                  radius: 13,
                  userId: _owner!.id,
                  username: _owner!.username,
                ),
                const SizedBox(width: 8),
                Text(
                  _owner!.username.isNotEmpty
                      ? _owner!.username
                      : _owner!.nomeCompleto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
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
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD8D7E6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementSection extends StatelessWidget {
  const _ManagementSection({
    required this.data,
    required this.isAdmin,
    required this.onModificaCasa,
  });

  final _HubCasaData data;
  final bool isAdmin;
  final VoidCallback onModificaCasa;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestione',
          style: TextStyle(
            color: Color(0xFF3B3B46),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        if (isAdmin) ...[
          _ManagementAction(
            icon: Icons.settings_outlined,
            title: 'Impostazioni casa',
            onTap: onModificaCasa,
          ),
          const SizedBox(height: 12),
        ],
        _ManagementAction(
          icon: Icons.group_outlined,
          title: 'Coinquilini e ruoli',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListaCoinquiliniScreen(casaId: data.casa.id),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _ManagementAction(
          icon: Icons.folder_open,
          title: 'Documenti condivisi',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ArchivioDocumentiVuotoScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (isAdmin) ...[
          _ManagementAction(
            icon: Icons.link,
            title: 'Condividi codice d\'invito',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CondividiCodiceScreen(casaId: data.casa.id),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        _ManagementAction(
          icon: Icons.house_siding,
          title: 'Lista case',
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ListaCaseScreen()));
          },
        ),
      ],
    );
  }
}

class _ManagementAction extends StatelessWidget {
  const _ManagementAction({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2341),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1734),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminWarningCard extends StatelessWidget {
  const _AdminWarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF8F5A26),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Solo l\'Amministratore puo modificare le impostazioni della casa',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteHouseButton extends StatelessWidget {
  const _DeleteHouseButton({required this.onPressed, required this.isOwner});

  final VoidCallback onPressed;
  final bool isOwner;

  static const _radius = BorderRadius.all(Radius.circular(12));
  static const _color = AppColors.errorStrong;

  @override
  Widget build(BuildContext context) {
    final label = isOwner ? 'Elimina la casa' : 'Lascia la casa';
    final icon = isOwner ? Icons.cancel_outlined : Icons.logout_rounded;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.50, 0.00),
            end: const Alignment(0.50, 1.00),
            colors: [
              const Color(0xFF510808).withValues(alpha: 0.9),
              const Color(0xFF510808).withValues(alpha: 1.0),
            ],
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: _color,
            ),
            borderRadius: _radius,
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: _radius),
          ),
          icon: Icon(icon, size: 20, color: _color),
          label: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _color,
            ),
          ),
        ),
      ),
    );
  }
}
