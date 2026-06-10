import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/casa/screens/archivio_documenti_vuoto.dart';
import 'package:coincasa_app/features/casa/screens/condividi_codice.dart';
import 'package:coincasa_app/features/casa/screens/elimina_casa.dart';
import 'package:coincasa_app/features/casa/screens/lista_case.dart';
import 'package:coincasa_app/features/casa/screens/lista_coinquilini.dart';

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

class HubCasaAdminScreen extends StatefulWidget {
  const HubCasaAdminScreen({super.key, this.casaId});

  final String? casaId;

  @override
  State<HubCasaAdminScreen> createState() => _HubCasaAdminScreenState();
}

class _HubCasaAdminScreenState extends State<HubCasaAdminScreen> {
  late Future<_HubCasaData> _future;
  late ActiveCasaController _activeCasaController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    _activeCasaController = ActiveCasaScope.read(context);
    _future = _load();
    _initialized = true;
  }

  Future<_HubCasaData> _load() async {
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      throw StateError('Nessuna casa disponibile.');
    }

    final selected = widget.casaId == null
        ? _activeCasaController.resolveCasa(caseUtente)
        : caseUtente.firstWhere(
            (casa) => casa.id == widget.casaId,
            orElse: () => caseUtente.first,
          );
    if (widget.casaId != null) {
      _activeCasaController.selectCasa(selected.id);
    }

    final results = await Future.wait<dynamic>([
      ApiProvider.casa.getById(selected.id),
      ApiProvider.casa.listInquilini(selected.id),
      ApiProvider.spese.list(selected.id),
      ApiProvider.turni.list(selected.id),
    ]);

    final inquilini = results[1] as List<Inquilino>;
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

    return _HubCasaData(
      casa: results[0] as Casa,
      inquilini: inquilini,
      speseCount: (results[2] as List).length,
      turniCount: (results[3] as List).length,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _deleteCasa(_HubCasaData data) async {
    final confirmed = await showEliminaCasaDialog(
      context,
      nomeCasa: data.casa.nome,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.brandPrimary,
        centerTitle: true,
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
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                children: [
                  _HouseHeaderCard(data: data),
                  const SizedBox(height: 20),
                  _ManagementSection(data: data),
                  const SizedBox(height: 20),
                  const _AdminWarningCard(),
                  const SizedBox(height: 16),
                  _DeleteHouseButton(onPressed: () => _deleteCasa(data)),
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
    required this.turniCount,
  });

  final Casa casa;
  final List<Inquilino> inquilini;
  final int speseCount;
  final int turniCount;
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
  const _HouseHeaderCard({required this.data});

  final _HubCasaData data;

  String get _address {
    final parts = [
      data.casa.indirizzo,
      data.casa.citta,
    ].where((part) => part.trim().isNotEmpty).join(' - ');
    return '${data.casa.tipoCasa.isEmpty ? 'Casa' : data.casa.tipoCasa} - $parts';
  }

  String get _roleLabel {
    if (data.casa.ruolo == 'HomeAdmin') {
      return 'Admin';
    }
    if (data.casa.ruolo == 'Inquilino' || data.casa.ruolo.isEmpty) {
      return 'Membro';
    }
    return data.casa.ruolo;
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
              const Expanded(
                child: _StatisticChip(
                  value: '0',
                  label: 'Scadenze',
                  valueColor: Color(0xFFF9A825),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StatisticChip(
                  value: '0',
                  label: 'Problemi',
                  valueColor: Color(0xFF2F9BFF),
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
  const _ManagementSection({required this.data});

  final _HubCasaData data;

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
  const _DeleteHouseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.errorContainerStrong,
          foregroundColor: AppColors.errorStrong,
          side: const BorderSide(color: AppColors.errorStrong, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          'lascia la casa',
          style: AppTextStyles.buttonCompact.copyWith(
            color: AppColors.errorStrong,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
