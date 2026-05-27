import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/features/casa/screens/archivio_documenti_vuoto.dart';
import 'package:coincasa_app/features/casa/screens/condividi_codice.dart';
import 'package:coincasa_app/features/casa/screens/elimina_casa.dart';
import 'package:coincasa_app/features/casa/screens/lista_case.dart';
import 'package:coincasa_app/features/casa/screens/lista_coinquilini.dart';
import 'package:coincasa_app/features/casa/screens/modifica_casa.dart';

class HubCasaAdminScreen extends StatefulWidget {
  const HubCasaAdminScreen({super.key, this.casaId});

  final String? casaId;

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
    final caseUtente = await ApiProvider.casa.list();
    if (caseUtente.isEmpty) {
      throw StateError('Nessuna casa disponibile.');
    }

    final selected = widget.casaId == null
        ? caseUtente.first
        : caseUtente.firstWhere(
            (casa) => casa.id == widget.casaId,
            orElse: () => caseUtente.first,
          );

    final results = await Future.wait<dynamic>([
      ApiProvider.casa.getById(selected.id),
      ApiProvider.casa.listInquilini(selected.id),
      ApiProvider.spese.list(selected.id),
      ApiProvider.turni.list(selected.id),
    ]);

    return _HubCasaData(
      casa: results[0] as Casa,
      inquilini: results[1] as List<Inquilino>,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF5A3AE0),
        title: const Text('Hub Casa'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF3F33B8),
              child: Image(
                image: AssetImage('assets/Icons/Profilo_utente_icona.png'),
                width: 20,
                height: 20,
                fit: BoxFit.contain,
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
              return _HubErrorState(onRetry: _reload);
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _HouseHeaderCard(data: data),
                  const SizedBox(height: 20),
                  _ManagementSection(data: data, onCasaUpdated: _reload),
                  const SizedBox(height: 20),
                  _DeleteHouseButton(onPressed: () => _deleteCasa(data)),
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
    final parts = [data.casa.indirizzo, data.casa.citta]
        .where((part) => part.trim().isNotEmpty)
        .join(' - ');
    return '${data.casa.tipoCasa.isEmpty ? 'Casa' : data.casa.tipoCasa} - $parts';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1947),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F2B75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: Colors.white,
                  size: 28,
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
                        color: Color(0xFFB8B8D5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                  color: const Color(0xFF7E5BF6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Casa',
                  style: TextStyle(
                    color: Colors.white,
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
                  label: 'membri',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(
                  value: '${data.speseCount}',
                  label: 'Spese',
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StatisticChip(value: '0', label: 'Scadenze'),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StatisticChip(value: '0', label: 'Problemi'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(
                  value: '${data.turniCount}',
                  label: 'Turni',
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
  const _StatisticChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB8B8D5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
    required this.onCasaUpdated,
  });

  final _HubCasaData data;
  final VoidCallback onCasaUpdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestione',
          style: TextStyle(
            color: Color(0xFF1E1B2E),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _ManagementAction(
          icon: Icons.edit_outlined,
          title: 'Modifica informazioni',
          subtitle: 'Aggiorna nome, indirizzo e tipologia',
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
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
            if (updated == true) {
              onCasaUpdated();
            }
          },
        ),
        const SizedBox(height: 12),
        _ManagementAction(
          icon: Icons.group_outlined,
          title: 'Coinquilini e ruoli',
          subtitle: '${data.inquilini.length} membri nella casa',
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
          icon: Icons.link,
          title: 'Condividi link invito',
          subtitle: 'Invia l invito a un amico',
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
          icon: Icons.folder_open,
          title: 'Documenti condivisi',
          subtitle: 'Archivio documenti',
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
          icon: Icons.house_siding,
          title: 'Lista case',
          subtitle: 'Torna alle tue abitazioni',
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
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E0F5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFECEBFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.brandPrimary, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E1B2E),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF8A8A9C),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Color(0xFF9A97B0),
        ),
        onTap: onTap,
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
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD12C3D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Elimina casa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
