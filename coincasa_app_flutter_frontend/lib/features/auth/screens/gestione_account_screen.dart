import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/services/session_manager.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';

class GestioneAccountScreen extends StatelessWidget {
  const GestioneAccountScreen({super.key});

  static const routeName = '/account';

  @override
  Widget build(BuildContext context) {
    final client = ApiProvider.client;

    final displayName =
        client.currentUserUsername ?? 'Utente';
    final email = client.currentUserEmail ?? 'email@esempio.com';
    final username = client.currentUserUsername ?? displayName;

    return Scaffold(
      backgroundColor: const Color(0xFF100D22),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back arrow
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed('/dashboard'),
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    UserAvatar(
                      radius: 42,
                      userId: client.currentUserAvatarSeed,
                      username: username,
                    ),
                    const SizedBox(height: 14),

                    // Nome (Tu)
                    Text(
                      '$displayName (Tu)',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Casa
                    Text(
                      'Casa Verdi',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB6B6D2),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sezione label
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DATI ACCOUNT',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB6B6D2),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Card dati
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A3A),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          _AccountRow(
                            label: 'Nome utente',
                            value: displayName,
                            onModifica: () =>
                                _showModificaSnackBar(context, 'nome utente'),
                          ),
                          const _AccountDivider(),
                          _AccountRow(
                            label: 'Email',
                            value: email,
                            onModifica: () =>
                                _showModificaSnackBar(context, 'email'),
                          ),
                          const _AccountDivider(),
                          _AccountRow(
                            label: 'Password',
                            value: '••••••••',
                            onModifica: () =>
                                _showModificaSnackBar(context, 'password'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Logout — piccolo, allineato a destra
                    Align(
                      alignment: Alignment.centerRight,
                      child: _LogoutButton(
                        onPressed: () => _handleLogout(context),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Elimina account — incollato al fondo
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _EliminaAccountButton(
                onPressed: () => _showEliminaSnackBar(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModificaSnackBar(BuildContext context, String campo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modifica $campo non ancora implementata.')),
    );
  }

  void _showEliminaSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Eliminazione account non ancora implementata.')),
    );
  }

  void _handleLogout(BuildContext context) {
    SessionManager.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.value,
    required this.onModifica,
  });

  final String label;
  final String value;
  final VoidCallback onModifica;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF8A8AB0),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onModifica,
                child: Text(
                  'Modifica',
                  style: GoogleFonts.inter(
                    color: AppColors.brandAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountDivider extends StatelessWidget {
  const _AccountDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFF252B50),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _radius = BorderRadius.all(Radius.circular(12));
  static const _borderColor = AppColors.brandAccent;
  static const _fillTop = Color(0xFF7B4FD4);
  static const _fillBase = AppColors.brandPrimary;
  static const _fillBottom = Color(0xFF3A1F8A);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.50, 0.00),
            end: const Alignment(0.50, 1.00),
            colors: [
              Color.lerp(_fillTop, Colors.white, 0.18)!,
              _fillBase,
              _fillBottom,
            ],
            stops: const [0.0, 0.60, 1.0],
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: _borderColor,
            ),
            borderRadius: _radius,
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: const RoundedRectangleBorder(borderRadius: _radius),
          ),
          icon: const Icon(Icons.logout_rounded, size: 17, color: Colors.white),
          label: Text(
            'Logout',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _EliminaAccountButton extends StatelessWidget {
  const _EliminaAccountButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _radius = BorderRadius.all(Radius.circular(12));
  static const _color = AppColors.errorStrong;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.50, 0.00),
            end: const Alignment(0.50, 1.00),
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.00),
            ],
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: _color,
            ),
            borderRadius: _radius,
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: _radius),
          ),
          icon: const Icon(Icons.cancel_outlined, size: 20, color: _color),
          label: Text(
            'Elimina account',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _color,
            ),
          ),
        ),
      ),
    );
  }
}
