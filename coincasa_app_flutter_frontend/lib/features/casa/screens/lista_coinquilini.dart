import 'package:flutter/material.dart';
import 'package:coincasa_app/features/casa/screens/condividi_codice1.dart';
import 'package:coincasa_app/features/casa/screens/elimina_coinquilino.dart'
    show showEliminaCoinquilinoDialog; // ← aggiunto
import 'package:coincasa_app/features/casa/screens/profilo_admin.dart';
import 'package:coincasa_app/features/casa/screens/profilo_coinquilino.dart';
import 'package:coincasa_app/features/casa/screens/promuovi_coinquilino.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class ListaCoinquiliniScreen extends StatelessWidget {
  const ListaCoinquiliniScreen({super.key});

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

  static final List<_Coinquilino> _coinquilini = [
    const _Coinquilino(
      name: 'Marco Rossi (Tu)',
      email: 'm.rossi@gmail.com',
      joinDate: 'Dal 10 gen 2026',
      role: 'Admin',
      isAdmin: true,
    ),
    const _Coinquilino(
      name: 'Alice Bianchi',
      email: 'a.bianchi@gmail.com',
      joinDate: 'Dal 12 gen 2026',
      role: 'Membro',
    ),
    const _Coinquilino(
      name: 'Francesco Verdi',
      email: 'f.verdi@gmail.com',
      joinDate: 'Dal 15 gen 2026',
      role: 'Membro',
    ),
    const _Coinquilino(
      name: 'Sara Neri',
      email: 's.neri@gmail.com',
      joinDate: 'Dal 18 gen 2026',
      role: 'Membro',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF5A3AE0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: Navigator.of(context).pop,
        ),
        title: const Text('Lista coinquilini'),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '4 membri',
                    style: TextStyle(
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
                        itemCount: _coinquilini.length,
                        separatorBuilder: (context, index) => const Divider(
                          color: Color(0xFF2A2E51),
                          height: 32,
                          thickness: 1,
                        ),
                        itemBuilder: (context, index) {
                          final coinquilino = _coinquilini[index];
                          return _CoinquilinoTile(
                            coinquilino: coinquilino,
                            onTap: coinquilino.name.startsWith('Marco')
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ProfiloAdminScreen(),
                                      ),
                                    );
                                  }
                                : coinquilino.name.startsWith('Francesco')
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ProfiloCoinquilinoScreen(),
                                      ),
                                    );
                                  }
                                : null,
                            // ── Callback "Rimuovi" collegato ──────────────
                            onRimuovi: coinquilino.isAdmin
                                ? null // l'admin non può rimuovere se stesso
                                : () {
                                    showEliminaCoinquilinoDialog(
                                      context,
                                      nomeCoinquilino: coinquilino.name
                                          .split(' ')
                                          .first,
                                      iniziali: _initials(coinquilino.name),
                                      onRimuovi: () {
                                        // TODO: chiama API rimozione
                                      },
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
                      onPressed: () => showCondividiCodiceDialog(context),
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
            ),
            Positioned(
              right: 24,
              bottom: 30,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: AppColors.brandPrimary,
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1B2E),
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: const Color(0xFF8A8A9C),
        showUnselectedLabels: true,
        elevation: 8,
        items: _navigationItems,
      ),
    );
  }
}

// ─── Helper per le iniziali (usato anche da EliminaCoinquilinoScreen) ─────────
String _initials(String name) {
  final words = name.split(' ');
  if (words.length >= 2) {
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
  return name.substring(0, 2).toUpperCase();
}

class _Coinquilino {
  final String name;
  final String email;
  final String joinDate;
  final String role;
  final bool isAdmin;

  const _Coinquilino({
    required this.name,
    required this.email,
    required this.joinDate,
    required this.role,
    this.isAdmin = false,
  });
}

class _CoinquilinoTile extends StatelessWidget {
  final _Coinquilino coinquilino;
  final VoidCallback? onTap;
  final VoidCallback? onRimuovi; // ← nuovo parametro

  const _CoinquilinoTile({
    required this.coinquilino,
    this.onTap,
    this.onRimuovi, // ← aggiunto
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: coinquilino.isAdmin
                    ? AppColors.brandPrimary
                    : const Color(0xFF3B456D),
                child: Text(
                  _initials(coinquilino.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coinquilino.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
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
                                text: coinquilino.role,
                                style: TextStyle(
                                  color: coinquilino.role == 'Admin'
                                      ? const Color(0xFF7E5BF6)
                                      : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      coinquilino.joinDate,
                      style: const TextStyle(
                        color: Color(0xFF7A7D96),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              if (!coinquilino.isAdmin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ActionChip(
                      label: 'Promuovi',
                      color: const Color(0xFF6D5FFF),
                      onTap: () {
                        showPromuoviCoinquilinoDialog(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    // ── Bottone Rimuovi collegato ─────────────────────────
                    _ActionChip(
                      label: 'Rimuovi',
                      color: const Color(0xFFD12C3D),
                      onTap:
                          onRimuovi, // ← usa il callback passato dall'esterno
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({required this.label, required this.color, this.onTap});

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
