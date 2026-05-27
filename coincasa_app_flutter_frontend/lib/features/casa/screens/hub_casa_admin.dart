import 'package:flutter/material.dart';
import 'package:coincasa_app/features/casa/screens/archivio_documenti_vuoto.dart';
import 'package:coincasa_app/features/casa/screens/condividi_codice.dart';
import 'package:coincasa_app/features/casa/screens/elimina_casa.dart';
import 'package:coincasa_app/features/casa/screens/lista_case.dart';
import 'package:coincasa_app/features/casa/screens/lista_coinquilini.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class HubCasaAdminScreen extends StatefulWidget {
  const HubCasaAdminScreen({super.key});

  @override
  State<HubCasaAdminScreen> createState() => _HubCasaAdminScreenState();
}

class _HubCasaAdminScreenState extends State<HubCasaAdminScreen> {
  int _selectedIndex = 0;

  static const List<BottomNavigationBarItem> _navigationItems = [
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/home.png'),
          fit: BoxFit.contain,
        ),
      ),
      activeIcon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/home.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/spese.png'),
          fit: BoxFit.contain,
        ),
      ),
      activeIcon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/spese.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Spese',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/turni.png'),
          fit: BoxFit.contain,
        ),
      ),
      activeIcon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/turni.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Turni',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/reminder.png'),
          fit: BoxFit.contain,
        ),
      ),
      activeIcon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/reminder.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Scadenze',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/problemi.png'),
          fit: BoxFit.contain,
        ),
      ),
      activeIcon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/problemi.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Problemi',
    ),
  ];

  void _onNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF5A3AE0),
        title: const Text('Hub Casa'),
        actions: const [
          Padding(
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 146),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _HouseHeaderCard(),
                  SizedBox(height: 20),
                  _ManagementSection(),
                  SizedBox(height: 20),
                  _DeleteHouseButton(),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 30,
              child: FloatingActionButton(
                onPressed: null,
                backgroundColor: AppColors.brandPrimary,
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigationTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color.fromARGB(255, 30, 27, 46),
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: const Color(0xFF8A8A9C),
        showUnselectedLabels: true,
        elevation: 8,
        items: _navigationItems,
      ),
    );
  }
}

class _HouseHeaderCard extends StatelessWidget {
  const _HouseHeaderCard();

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
                  children: const [
                    Text(
                      'Casa Verdi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Appartamento · Via Di Casal Bruciato, 18 - Roma',
                      style: TextStyle(
                        color: Color(0xFFB8B8D5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
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
                  'Admin',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: _StatisticChip(value: '0', label: 'membri'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(value: '0', label: 'Spese'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(value: '0', label: 'Scadenze'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(value: '0', label: 'Problemi'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatisticChip(value: '0', label: 'Turni'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticChip extends StatelessWidget {
  final String value;
  final String label;

  const _StatisticChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
  const _ManagementSection();

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
          icon: Icons.group_outlined,
          title: 'Coinquilini e ruoli',
          subtitle: 'Gestisci inviti e permessi',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ListaCoinquiliniScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _ManagementAction(
          icon: Icons.link,
          title: 'Condividi link invito',
          subtitle: 'Invia l’invito a un amico',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CondividiCodiceScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _ManagementAction(
          icon: Icons.folder_open,
          title: 'Documenti condivisi',
          subtitle: 'Apri file e note',
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ManagementAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

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
  const _DeleteHouseButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          showEliminaCasaDialog(context);
        },
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
