import 'package:flutter/material.dart';
import 'package:coincasa_app/features/casa/screens/hub_casa_admin.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class CasaPreSchermataHubCasaScreen extends StatelessWidget {
  final String houseName;
  final String inviteCode;

  const CasaPreSchermataHubCasaScreen({
    super.key,
    required this.houseName,
    required this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedHouseName = houseName.trim();
    final displayHouseName = normalizedHouseName.isEmpty
        ? 'Casa'
        : normalizedHouseName.toLowerCase().startsWith('casa ')
        ? normalizedHouseName
        : 'Casa $normalizedHouseName';
    final title = '$displayHouseName Creata!';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0828),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/Icons/pngtree-green-check-mark-icon-symbol-of-approval-and-confirmation-png-image_15397347 1.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sei l\'Amministratore della casa.\nCondividi il codice con i tuoi coinquilini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB8B8D5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _InviteCodeBox(inviteCode: inviteCode),
                ],
              ),
            ),
            Center(child: _WelcomeCard(displayHouseName: displayHouseName)),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeBox extends StatelessWidget {
  final String inviteCode;

  const _InviteCodeBox({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF151138),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B3A5E), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Codice invito',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB8B8D5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  inviteCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Codice pronto per la condivisione',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB8B8D5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String displayHouseName;

  const _WelcomeCard({required this.displayHouseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF09031F),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFD8F3FF),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x77000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/Icons/home_auth_icon.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Benvenuto in\n$displayHouseName!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Ti sei unito alla casa con\nsuccesso. Ora puoi\ngestire tutto insieme ai\ntuoi coinquilini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.08,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const HubCasaAdminScreen(),
                ),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFC1A8FF), width: 1),
              ),
            ),
            child: const Text(
              'Vai all\'Hub Casa',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
