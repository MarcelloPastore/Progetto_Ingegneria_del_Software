import 'package:flutter/material.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/casa/screens/compilazione_form_crea_casa.dart';
import 'package:coincasa_app/features/casa/screens/hub_casa_admin.dart';

class ListaCaseScreen extends StatefulWidget {
  const ListaCaseScreen({super.key});

  @override
  State<ListaCaseScreen> createState() => _ListaCaseScreenState();
}

class _ListaCaseScreenState extends State<ListaCaseScreen> {
  late Future<List<Casa>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiProvider.casa.list();
  }

  void _reload() {
    setState(() {
      _future = ApiProvider.casa.list();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09031F),
      body: SafeArea(
        child: FutureBuilder<List<Casa>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _reload);
            }

            final caseUtente = snapshot.data ?? const [];
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(caseCount: caseUtente.length),
                  const SizedBox(height: 20),
                  Expanded(
                    child: caseUtente.isEmpty
                        ? const Center(
                            child: Text(
                              'Nessuna casa attiva.',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _reload(),
                            child: ListView.separated(
                              itemCount: caseUtente.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 20),
                              itemBuilder: (context, index) {
                                final casa = caseUtente[index];
                                return _HouseCard(
                                  casa: casa,
                                  onTap: () {
                                    ActiveCasaScope.read(
                                      context,
                                    ).selectCasa(casa.id);
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            HubCasaAdminScreen(casaId: casa.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const CompilazioneFormCreaCasaScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFF5A2FC5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aggiungi casa',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
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
          const Icon(Icons.wifi_off, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Non e possibile caricare le case.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.caseCount});

  final int caseCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 34,
          height: 52,
          child: IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.brandPrimary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Le mie case',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$caseCount ${caseCount == 1 ? 'casa attiva' : 'case attive'}',
                style: const TextStyle(
                  color: Color(0xFF9D77FF),
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFF3F33B8),
          child: Image(
            image: AssetImage('assets/Icons/Profilo_utente_icona.png'),
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _HouseCard extends StatelessWidget {
  const _HouseCard({required this.casa, this.onTap});

  final Casa casa;
  final VoidCallback? onTap;

  String get _address {
    final parts = [casa.indirizzo, casa.citta]
        .where((part) => part.trim().isNotEmpty)
        .join(' - ');
    return parts.isEmpty ? 'Indirizzo non disponibile' : parts;
  }

  String get _role {
    if (casa.ruolo == 'HomeAdmin') {
      return 'Admin';
    }
    if (casa.ruolo == 'Inquilino') {
      return 'Membro';
    }
    return 'Casa';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF17213B),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Image.asset(
                  'assets/Icons/appartamenti-moderni-lusso 1.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      casa.nome.isEmpty ? 'Casa senza nome' : casa.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _address,
                      style: const TextStyle(
                        color: Color(0xFFD2D4DF),
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
