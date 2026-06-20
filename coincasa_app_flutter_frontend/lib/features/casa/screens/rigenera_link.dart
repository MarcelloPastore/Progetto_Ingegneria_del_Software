import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';

class RigeneraLinkScreen extends StatelessWidget {
  const RigeneraLinkScreen({super.key});

  static const String _inviteCode = 'CX-4821';
  static const String _inviteLink = 'coincasa.app/join/CX-4821';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Condividi il codice o link per aggiungere\nun nuovo coinquilino',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE0E3F2),
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _CodeCard(),
              const SizedBox(height: 28),
              const _CopyCodeButton(),
              const SizedBox(height: 20),
              const _DisabledRegenerateButton(),
              const SizedBox(height: 28),
              const _SharePanel(),
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
    return SizedBox(
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: IconButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: Navigator.of(context).pop,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Text(
            'Codice Invito',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF9CA5DA), width: 2),
        ),
        child: const Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'C X - 4 8 2 1',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'scade il 14 mag 2026 - 7 gg rimanenti',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFD2D4DF),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyCodeButton extends StatelessWidget {
  const _CopyCodeButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: SizedBox(
        height: 58,
        child: FilledButton(
          onPressed: () {
            Clipboard.setData(
              const ClipboardData(text: RigeneraLinkScreen._inviteCode),
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Codice copiato')));
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandSecondary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF9CA5DA), width: 2),
            ),
          ),
          child: const Text(
            'Copia codice',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _DisabledRegenerateButton extends StatelessWidget {
  const _DisabledRegenerateButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: SizedBox(
        height: 58,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            disabledForegroundColor: const Color(0xFF6F6A82),
            side: const BorderSide(color: Color(0xFF6F6A82), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Rigenera link',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _SharePanel extends StatelessWidget {
  const _SharePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandAccent, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShareHeader(),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
            children: const [
              _ShareItem(
                icon: Icons.copy_rounded,
                label: 'Copia',
                backgroundColor: Color(0xFFE5E5E5),
                iconColor: Color(0xFF595959),
                showShadow: true,
              ),
              _ShareItem(
                label: 'Francesco',
                avatarText: 'F',
                backgroundColor: Color(0xFF355A82),
                iconColor: Color(0xFF63C6FF),
              ),
              _ShareItem(
                label: 'Marco',
                avatarText: 'M',
                backgroundColor: Color(0xFFC2FFD2),
                iconColor: Color(0xFF17611E),
              ),
              _ShareItem(
                label: 'Alice',
                avatarText: 'A',
                backgroundColor: Color(0xFFFFB79D),
                iconColor: Color(0xFF8B4B00),
              ),
              _ShareItem(
                icon: Icons.phone,
                label: 'Whatsapp',
                backgroundColor: Color(0xFF00C853),
                iconColor: Colors.white,
              ),
              _ShareItem(
                icon: Icons.mail_outline,
                label: 'Mail',
                backgroundColor: Color(0xFF64A9FF),
                iconColor: Colors.white,
              ),
              _ShareItem(
                icon: Icons.chat_bubble,
                label: 'Messaggi',
                backgroundColor: Color(0xFF47E550),
                iconColor: Colors.white,
              ),
              _ShareItem(
                icon: Icons.send,
                label: 'Telegram',
                backgroundColor: Color(0xFF10A9E8),
                iconColor: Colors.white,
              ),
              _ShareItem(
                icon: Icons.facebook,
                label: 'Facebook',
                backgroundColor: Color(0xFF1684F8),
                iconColor: Colors.white,
              ),
              _ShareItem(
                icon: Icons.camera_alt,
                label: 'Instagram',
                backgroundColor: Color(0xFFE24B8F),
                iconColor: Colors.white,
              ),
              _ShareItem(
                icon: Icons.more_horiz,
                label: 'Altro',
                backgroundColor: Color(0xFFE1E1E1),
                iconColor: Color(0xFF8D889C),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareHeader extends StatelessWidget {
  const _ShareHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Color(0xFF9D22C9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.home, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                RigeneraLinkScreen._inviteLink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'CoinCasa - Invito coinquilino',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            Clipboard.setData(
              const ClipboardData(text: RigeneraLinkScreen._inviteLink),
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Link copiato')));
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE0E0E0),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text(
            'copia',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ShareItem extends StatelessWidget {
  final IconData? icon;
  final String? avatarText;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final bool showShadow;

  const _ShareItem({
    this.icon,
    this.avatarText,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: showShadow
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: avatarText != null
                ? Text(
                    avatarText!,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Icon(icon, color: iconColor, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
