import 'package:flutter/material.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/features/casa/screens/hub_casa_admin.dart';
import 'package:coincasa_app/features/casa/screens/promuovi_coinquilino.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';

class ProfiloAdminScreen extends StatelessWidget {
  const ProfiloAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          onPressed: Navigator.of(context).pop,
        ),
        title: const Text(
          'Dettaglio Profilo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed('/account'),
              customBorder: const CircleBorder(),
              child: const _UserAvatar(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 124),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _AdminProfileCard(),
                  SizedBox(height: 28),
                  _AdminInfoCard(),
                  SizedBox(height: 20),
                  _SectionTitle('AZIONI(Admin)'),
                  SizedBox(height: 14),
                  _AdminActions(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      radius: 18,
      userId: ApiProvider.client.currentUserAvatarSeed,
      username: ApiProvider.client.currentUserUsername,
      showPresenceDot: true,
    );
  }
}

class _AdminProfileCard extends StatelessWidget {
  const _AdminProfileCard();

  @override
  Widget build(BuildContext context) {
    final displayName = ApiProvider.client.currentUserUsername
        ?? ApiProvider.client.currentUserDisplayName
        ?? 'Utente';
    final email = ApiProvider.client.currentUserEmail ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF17213B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          UserAvatar(
            radius: 45,
            userId: ApiProvider.client.currentUserAvatarSeed,
            username: ApiProvider.client.currentUserUsername,
          ),
          const SizedBox(height: 10),
          Text(
            '$displayName (tu)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD2D4DF),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminInfoCard extends StatelessWidget {
  const _AdminInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17213B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          _InfoRow(label: 'Amministratore dal', value: '10 Gen 2026'),
          _InfoRow(label: 'Spese pagate', value: '€89'),
          _InfoRow(
            label: 'Saldo',
            value: '+€120',
            valueColor: Color(0xFF25F28A),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD2D4DF),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF44434B),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  const _AdminActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 38),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton(
              onPressed: () => showPromuoviCoinquilinoDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5A2FC5),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0x665A2FC5),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFB7A5FF), width: 2),
                ),
              ),
              child: const Text(
                'Promuovi coinquilino',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const HubCasaAdminScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF2ECFF),
                foregroundColor: AppColors.brandPrimary,
                side: const BorderSide(color: AppColors.brandPrimary, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Torna all'Hub casa",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
