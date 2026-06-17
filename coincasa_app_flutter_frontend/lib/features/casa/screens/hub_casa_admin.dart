import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/utils/jwt_utils.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/casa/screens/archivio_documenti_vuoto.dart';
import 'package:coincasa_app/features/casa/screens/condividi_codice.dart';
import 'package:coincasa_app/features/casa/screens/elimina_casa.dart';
import 'package:coincasa_app/features/casa/screens/lista_case.dart';
import 'package:coincasa_app/features/casa/screens/lista_coinquilini.dart';
import 'package:coincasa_app/features/casa/screens/lascia_casa.dart';
import 'package:coincasa_app/features/casa/screens/modifica_casa.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';

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
    _me.setCasaContext(casaId: widget.casaId, ruolo: ruolo);
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


  Future<void> _deleteCasa(_HubCasaData data) async {
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
    if (confirmed != true) return;

    try {
      await ApiProvider.casa.delete(data.casa.id);
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

  Future<void> _leaveCasa(_HubCasaData data) async {
    final confirmed = await showLasciaCasaDialog(
      context,
      nomeCasa: data.casa.nome,
    );
    if (confirmed != true) return;

    final currentId = _me.currentUserId?.trim() ?? '';
    final spesePendenti = data.spese.where((spesa) {
      if (spesa.partecipanti.isEmpty) return false;
      return spesa.partecipanti.any((q) {
        final uid = (q['utenteId'] ?? q['idUtente'] ?? q['inquilinoId'] ?? (q['utente'] as Map?)?['id'])?.toString().trim() ?? '';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF5D35B0),
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Hub Casa',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/account'),
              child: UserAvatar(
                radius: 18,
                userId: _me.currentUserAvatarSeed,
                username: _me.currentUserUsername,
                displayName: _me.currentUserDisplayName,
                showPresenceDot: true,
                presenceDotColor: const Color(0xFFF75C6C),
              ),
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
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 44),
                    const SizedBox(height: 12),
                    const Text('Non è possibile caricare i dati della casa.'),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _reload, child: const Text('Riprova')),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            final isCurrentOwner = data.isCurrentUserOwner;
            final isAdmin = data.isAdmin;

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                children: [
                  _HouseHeaderCard(data: data, isAdmin: isAdmin),
                  const SizedBox(height: 24),
                  const Text(
                    'Gestione',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ManagementAction(
                    iconData: Icons.group_outlined,
                    iconColor: Colors.blue,
                    title: 'Coinquilini e ruoli',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ListaCoinquiliniScreen(casaId: data.casa.id)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isAdmin) ...[
                    _ManagementAction(
                      iconData: Icons.share_outlined,
                      iconColor: Colors.orange,
                      title: 'Condividi link invito',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => CondividiCodiceScreen(casaId: data.casa.id)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ManagementAction(
                      iconData: Icons.edit_outlined,
                      iconColor: const Color(0xFF7C4DFF),
                      title: 'Modifica informazioni casa',
                      onTap: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => ModificaCasaScreen(
                              casaId: data.casa.id,
                              name: data.casa.nome,
                              city: data.casa.citta,
                              address: data.casa.indirizzo,
                              type: data.casa.tipoCasa,
                            ),
                          ),
                        );
                        if (updated == true) _reload();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ManagementAction(
                    iconData: Icons.folder_open,
                    iconColor: Colors.redAccent,
                    title: 'Documenti condivisi',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ArchivioDocumentiVuotoScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ManagementAction(
                    iconData: Icons.list_alt_rounded,
                    iconColor: Colors.green,
                    title: 'Lista case',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ListaCaseScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
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

class _HouseHeaderCard extends StatelessWidget {
  const _HouseHeaderCard({required this.data, required this.isAdmin});

  final _HubCasaData data;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151B33),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
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
                      data.casa.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.casa.tipoCasa.isEmpty ? 'Appartamento' : data.casa.tipoCasa,
                      style: const TextStyle(
                        color: Color(0xFFB6B6D2),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E35B1),
                    borderRadius: BorderRadius.circular(10),
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
                value: '${data.inquilini.length}',
                label: 'Membri',
                valueColor: const Color(0xFF9B5BFF),
              ),
              _StatisticChip(
                value: '${data.speseCount}',
                label: 'Spese',
                valueColor: const Color(0xFF53D86A),
              ),
              _StatisticChip(
                value: '${data.scadenzeCount}',
                label: 'Scadenze',
                valueColor: const Color(0xFFF9A825),
              ),
              _StatisticChip(
                value: '${data.problemiCount}',
                label: 'Problemi',
                valueColor: const Color(0xFF2F9BFF),
              ),
              _StatisticChip(
                value: '${data.turniCount}',
                label: 'Turni',
                valueColor: const Color(0xFFB15CFF),
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
      decoration: BoxDecoration(
        color: const Color(0xFF151B33),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
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
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3155),
                  borderRadius: BorderRadius.circular(10),
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
        color: const Color(0xFF3A1111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF75C6C), width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: Color(0xFFF75C6C), size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFF75C6C),
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
