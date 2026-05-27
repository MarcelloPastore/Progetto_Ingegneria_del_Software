import 'package:flutter/material.dart';
import 'package:coincasa_app/features/casa/screens/compilazione_form_crea_casa.dart';
import 'package:coincasa_app/features/casa/screens/hub_casa_admin.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class ListaCaseScreen extends StatelessWidget {
  const ListaCaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09031F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 20),
              _HouseCard(
                iconPath: 'assets/Icons/16015286 1.png',
                name: 'Casa Verdi',
                address: 'Via Di Casal\nBruciato, 18 - Roma',
                role: 'Admin',
                roleBackground: AppColors.brandPrimary,
                balance: '-€21',
                balanceColor: const Color(0xFFFF5E5E),
                turns: '2',
                turnsColor: const Color(0xFFFFD35C),
                problems: '0',
                problemsColor: const Color(0xFF63C6FF),
                deadlines: '0',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HubCasaAdminScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const _HouseCard(
                iconPath: 'assets/Icons/images 6.png',
                name: 'Casa\nWoodstock',
                address: 'Via Zambini, 32 -\nBologna',
                role: 'Membro',
                roleBackground: Color(0xFFA9C7FF),
                roleTextColor: Color(0xFF1C4A87),
                balance: '+€21',
                balanceColor: Color(0xFF25F28A),
                turns: '0',
                problems: '0',
                deadlines: '0',
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CompilazioneFormCreaCasaScreen(),
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const HubCasaAdminScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.brandPrimary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Le mie case',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '2 case attive',
                style: TextStyle(
                  color: Color(0xFF9D77FF),
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
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
            Positioned(
              top: 1,
              right: 3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A62),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HouseCard extends StatelessWidget {
  final String iconPath;
  final String name;
  final String address;
  final String role;
  final Color roleBackground;
  final Color roleTextColor;
  final String balance;
  final Color balanceColor;
  final String turns;
  final Color turnsColor;
  final String problems;
  final Color problemsColor;
  final String deadlines;
  final VoidCallback? onTap;

  const _HouseCard({
    required this.iconPath,
    required this.name,
    required this.address,
    required this.role,
    required this.roleBackground,
    this.roleTextColor = Colors.white,
    required this.balance,
    required this.balanceColor,
    required this.turns,
    this.turnsColor = Colors.white,
    required this.problems,
    this.problemsColor = Colors.white,
    required this.deadlines,
    this.onTap,
  });

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
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    height: 62,
                    child: Image.asset(iconPath, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          address,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: roleTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _StatsGrid(
                children: [
                  _Stat(value: balance, label: 'Saldo', color: balanceColor),
                  _Stat(value: turns, label: 'Turni oggi', color: turnsColor),
                  _Stat(
                    value: deadlines,
                    label: int.tryParse(deadlines) == 1
                        ? 'Scadenza'
                        : 'Scadenze',
                  ),
                  _Stat(
                    value: problems,
                    label: int.tryParse(problems) == 1
                        ? 'Problema'
                        : 'Problemi',
                    color: problemsColor,
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

class _StatsGrid extends StatelessWidget {
  final List<Widget> children;

  const _StatsGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final useTwoColumns = constraints.maxWidth < 320;
        final columns = useTwoColumns ? 2 : 4;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({
    required this.value,
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFD2D4DF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
