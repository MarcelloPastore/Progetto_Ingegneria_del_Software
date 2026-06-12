import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showCondividiCodiceDialog(
  BuildContext context, {
  String inviteCode = 'CX-4821',
  String inviteLink = 'coincasa.app/join/CX-4821',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x8C000000),
    builder: (_) =>
        CondividiCodiceDialog(inviteCode: inviteCode, inviteLink: inviteLink),
  );
}

class CondividiCodiceDialog extends StatelessWidget {
  final String inviteCode;
  final String inviteLink;

  const CondividiCodiceDialog({
    super.key,
    required this.inviteCode,
    required this.inviteLink,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: _CondividiCard(inviteCode: inviteCode, inviteLink: inviteLink),
        ),
      ),
    );
  }
}

class _CondividiCard extends StatelessWidget {
  final String inviteCode;
  final String inviteLink;

  const _CondividiCard({required this.inviteCode, required this.inviteLink});

  // Contatti recenti simulati
  static const _contacts = [
    _Contact(name: 'Francesco', initial: 'F', color: Color(0xFF2A4A7F)),
    _Contact(name: 'Marco', initial: 'M', color: Color(0xFF3DAA6E)),
    _Contact(name: 'Alice', initial: 'A', color: Color(0xFFD4875A)),
  ];

  // App di condivisione
  static const _shareApps = [
    _ShareApp(name: 'Whatsapp', icon: _AppIcon.whatsapp),
    _ShareApp(name: 'Mail', icon: _AppIcon.mail),
    _ShareApp(name: 'Messaggi', icon: _AppIcon.messaggi),
    _ShareApp(name: 'Telegram', icon: _AppIcon.telegram),
    _ShareApp(name: 'Facebook', icon: _AppIcon.facebook),
    _ShareApp(name: 'Instagram', icon: _AppIcon.instagram),
    _ShareApp(name: 'Altro', icon: _AppIcon.altro),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7B3FE4), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Link box ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0B8FF), width: 1),
            ),
            child: Row(
              children: [
                // Icona home
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B2FD9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inviteLink,
                        style: const TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'CoinCasa · Invito coinquilino',
                        style: TextStyle(
                          color: Color(0xFF7A7A9A),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bottone copia link
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: inviteLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copiato!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'copia',
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Riga: Copia codice + Contatti ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Copia codice
              _ShareTarget(
                label: 'Copia',
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Codice copiato!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Color(0xFF555555),
                      size: 26,
                    ),
                  ),
                ),
              ),
              // Contatti recenti
              ..._contacts.map(
                (c) => _ShareTarget(
                  label: c.name,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: c.color,
                    child: Text(
                      c.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Grid app di condivisione ────────────────────────────────────
          _buildAppRow(context, _shareApps.take(4).toList()),
          const SizedBox(height: 16),
          _buildAppRow(context, _shareApps.skip(4).toList()),
        ],
      ),
    );
  }

  Widget _buildAppRow(BuildContext context, List<_ShareApp> apps) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: apps.map((app) {
        return _ShareTarget(
          label: app.name,
          child: _AppIconWidget(icon: app.icon),
        );
      }).toList(),
    );
  }
}

// ── Singolo elemento condivisione (icona + label) ─────────────────────────────
class _ShareTarget extends StatelessWidget {
  final Widget child;
  final String label;

  const _ShareTarget({required this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Icone app ─────────────────────────────────────────────────────────────────
enum _AppIcon { whatsapp, mail, messaggi, telegram, facebook, instagram, altro }

class _AppIconWidget extends StatelessWidget {
  final _AppIcon icon;

  const _AppIconWidget({required this.icon});

  @override
  Widget build(BuildContext context) {
    switch (icon) {
      case _AppIcon.whatsapp:
        return _CircleIcon(
          color: const Color(0xFF25D366),
          child: _WhatsappSvg(),
        );
      case _AppIcon.mail:
        return _CircleIcon(
          color: const Color(0xFF1E90FF),
          child: const Icon(Icons.mail_rounded, color: Colors.white, size: 28),
        );
      case _AppIcon.messaggi:
        return _CircleIcon(
          color: const Color(0xFF34C759),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 26,
          ),
        );
      case _AppIcon.telegram:
        return _CircleIcon(
          color: const Color(0xFF229ED9),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 26),
        );
      case _AppIcon.facebook:
        return _CircleIcon(
          color: const Color(0xFF1877F2),
          child: const Icon(
            Icons.facebook_rounded,
            color: Colors.white,
            size: 30,
          ),
        );
      case _AppIcon.instagram:
        return _CircleIcon(
          gradient: const LinearGradient(
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 26,
          ),
        );
      case _AppIcon.altro:
        return _CircleIcon(
          color: const Color(0xFFCCCCCC),
          child: const Icon(
            Icons.more_horiz_rounded,
            color: Colors.white,
            size: 28,
          ),
        );
    }
  }
}

class _CircleIcon extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;

  const _CircleIcon({required this.child, this.color, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
}

class _WhatsappSvg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.chat, color: Colors.white, size: 28);
  }
}

// ── Modelli dati interni ──────────────────────────────────────────────────────
class _Contact {
  final String name;
  final String initial;
  final Color color;

  const _Contact({
    required this.name,
    required this.initial,
    required this.color,
  });
}

class _ShareApp {
  final String name;
  final _AppIcon icon;

  const _ShareApp({required this.name, required this.icon});
}
