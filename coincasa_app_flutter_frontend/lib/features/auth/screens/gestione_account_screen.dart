import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:coincasa_app/core/api/api_client.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/services/session_manager.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/features/auth/screens/check_email_screen.dart';
import 'package:coincasa_app/features/auth/screens/elimina_account_success_screen.dart';
import 'package:coincasa_app/features/auth/screens/modifica_password_screen.dart';

class GestioneAccountScreen extends StatefulWidget {
  const GestioneAccountScreen({super.key});

  static const routeName = '/account';

  @override
  State<GestioneAccountScreen> createState() => _GestioneAccountScreenState();
}

class _GestioneAccountScreenState extends State<GestioneAccountScreen> {
  bool _isEditingUsername = false;
  final _newUsernameController = TextEditingController();
  String? _usernameError;

  bool _isEditingEmail = false;
  final _newEmailController = TextEditingController();
  String? _emailError;

  bool _isConfirming = false;

  int _avatarTapCount = 0;

  void _onAvatarTap() {
    _avatarTapCount++;
    if (_avatarTapCount >= 7) {
      _avatarTapCount = 0;
      _showEasterEgg();
    }
  }

  void _showEasterEgg() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _EasterEggSheet(),
    );
  }

  @override
  void dispose() {
    _newUsernameController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  void _startEditUsername() {
    _newUsernameController.clear();
    setState(() {
      _isEditingUsername = true;
      _usernameError = null;
    });
  }

  void _cancelEditUsername() {
    _newUsernameController.clear();
    setState(() {
      _isEditingUsername = false;
      _usernameError = null;
    });
  }

  Future<void> _confirmEditUsername(String currentUsername) async {
    if (_isConfirming) return;
    final newUsername = _newUsernameController.text.trim();

    if (newUsername.isEmpty) {
      setState(() => _usernameError = 'Inserisci un nome utente.');
      return;
    }
    if (newUsername == currentUsername) {
      setState(
        () => _usernameError = 'Il nuovo username coincide con quello attuale.',
      );
      return;
    }

    setState(() {
      _isConfirming = true;
      _usernameError = null;
    });
    try {
      final saved = await ApiProvider.account.patchUsername(newUsername);
      await SessionManager.updateUsername(saved);
      if (!mounted) return;
      setState(() {
        _isEditingUsername = false;
        _isConfirming = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 409
          ? 'Username già in uso, scegline un altro.'
          : 'Modifica non riuscita. Riprova.';
      setState(() {
        _usernameError = msg;
        _isConfirming = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _usernameError = 'Modifica non riuscita. Riprova.';
        _isConfirming = false;
      });
    }
  }

  void _startEditEmail() {
    _newEmailController.clear();
    setState(() {
      _isEditingEmail = true;
      _emailError = null;
    });
  }

  void _cancelEditEmail() {
    _newEmailController.clear();
    setState(() {
      _isEditingEmail = false;
      _emailError = null;
    });
  }

  Future<void> _confirmEditEmail(String currentEmail) async {
    if (_isConfirming) return;
    final newEmail = _newEmailController.text.trim();

    if (newEmail.isEmpty) {
      setState(() => _emailError = 'Inserisci un indirizzo email.');
      return;
    }
    if (newEmail == currentEmail) {
      setState(
        () => _emailError = 'La nuova email coincide con quella attuale.',
      );
      return;
    }
    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      setState(() => _emailError = 'Inserisci un indirizzo email valido.');
      return;
    }

    setState(() {
      _isConfirming = true;
      _emailError = null;
    });
    try {
      final confirmedEmail = await ApiProvider.account.patchEmail(newEmail);
      await SessionManager.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CheckEmailScreen(email: confirmedEmail),
        ),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 409
          ? 'Email già in uso da un altro account.'
          : 'Modifica non riuscita. Riprova.';
      setState(() {
        _emailError = msg;
        _isConfirming = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _emailError = 'Modifica non riuscita. Riprova.';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ApiProvider.client;
    final displayName = client.currentUserUsername ?? 'Utente';
    final email = client.currentUserEmail ?? 'email@esempio.com';
    final username = client.currentUserUsername ?? displayName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF100D22),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Back arrow ───────────────────────────────────────────────
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
                    onPressed: () {
                      if (_isEditingUsername) {
                        _cancelEditUsername();
                      } else if (_isEditingEmail) {
                        _cancelEditEmail();
                      } else {
                        Navigator.of(
                          context,
                        ).pushReplacementNamed('/dashboard');
                      }
                    },
                  ),
                ),
              ),

              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _onAvatarTap,
                        child: UserAvatar(
                          radius: 42,
                          userId: client.currentUserAvatarSeed,
                          username: username,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_isEditingUsername)
                        _FieldEditPanel(
                          fieldLabel: 'Nome Utente',
                          currentValue: username,
                          controller: _newUsernameController,
                          error: _usernameError,
                          hint: 'Nuovo username',
                        )
                      else if (_isEditingEmail)
                        _FieldEditPanel(
                          fieldLabel: 'Email',
                          currentValue: email,
                          controller: _newEmailController,
                          error: _emailError,
                          hint: 'nuova@email.com',
                          keyboardType: TextInputType.emailAddress,
                        )
                      else ...[
                        // ── Sezione label ────────────────────────────────
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

                        // ── Card dati ────────────────────────────────────
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
                                onModifica: _startEditUsername,
                              ),
                              const _AccountDivider(),
                              _AccountRow(
                                label: 'Email',
                                value: email,
                                onModifica: _startEditEmail,
                              ),
                              const _AccountDivider(),
                              _AccountRow(
                                label: 'Password',
                                value: '••••••••',
                                onModifica: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ModificaPasswordScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Logout ───────────────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: _LogoutButton(
                            onPressed: () => _handleLogout(context),
                          ),
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // ── Pulsanti fondo (cambiano in base alla modalità) ──────────
              if (_isEditingUsername) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: _ConfermaButton(
                    isLoading: _isConfirming,
                    onPressed: _isConfirming
                        ? null
                        : () {
                            _confirmEditUsername(username);
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 52, 24),
                  child: _AnnullaEditButton(
                    onPressed: _isConfirming ? null : _cancelEditUsername,
                  ),
                ),
              ] else if (_isEditingEmail) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: _ConfermaButton(
                    isLoading: _isConfirming,
                    onPressed: _isConfirming
                        ? null
                        : () {
                            _confirmEditEmail(email);
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 52, 24),
                  child: _AnnullaEditButton(
                    onPressed: _isConfirming ? null : _cancelEditEmail,
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _EliminaAccountButton(
                    onPressed: () => _showEliminaDialog(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEliminaDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _EliminaAccountDialog(),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    ActiveCasaScope.read(context).clear();
    await SessionManager.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

// ---------------------------------------------------------------------------
// Pannello modifica campo generico (username / email)
// Solo label + campi + errore; pulsanti rimangono in fondo alla pagina.
// ---------------------------------------------------------------------------

class _FieldEditPanel extends StatelessWidget {
  const _FieldEditPanel({
    required this.fieldLabel,
    required this.currentValue,
    required this.controller,
    required this.error,
    required this.hint,
    this.keyboardType,
  });

  final String fieldLabel;
  final String currentValue;
  final TextEditingController controller;
  final String? error;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fieldLabel, style: AppTextStyles.label),
        const SizedBox(height: 10),

        // ── Campo Attuale (read-only) ────────────────────────────────────
        _InlineField(
          value: currentValue,
          tag: 'Attuale',
          tagColor: const Color(0xFFD4A800),
          readOnly: true,
        ),
        const SizedBox(height: 10),

        // ── Campo Nuovo (editabile) ──────────────────────────────────────
        _InlineField(
          controller: controller,
          hint: hint,
          tag: 'Nuovo',
          tagColor: AppColors.brandAccent,
          readOnly: false,
          hasError: error != null,
          keyboardType: keyboardType,
        ),

        if (error != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(error!, style: AppTextStyles.fieldError),
          ),
        ],
      ],
    );
  }
}

/// Textbox con tag testuale a destra e supporto readOnly.
/// Replica lo stile di [AuthField] con recoveryStyle:false.
class _InlineField extends StatelessWidget {
  const _InlineField({
    this.value,
    this.controller,
    this.hint,
    required this.tag,
    required this.tagColor,
    required this.readOnly,
    this.hasError = false,
    this.keyboardType,
  });

  final String? value;
  final TextEditingController? controller;
  final String? hint;
  final String tag;
  final Color tagColor;
  final bool readOnly;
  final bool hasError;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    // Controller fittizio per il campo read-only (pre-compilato, non modificabile).
    final ctrl = readOnly
        ? (TextEditingController(text: value ?? ''))
        : controller;

    return SizedBox(
      height: AppSizes.p58,
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: AppTextStyles.inputCompact,
        cursorColor: AppColors.focus,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          // Tag "Attuale" / "Nuovo" mostrato inline a destra
          suffix: Text(
            tag,
            style: TextStyle(
              color: tagColor,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          filled: true,
          fillColor: readOnly
              ? AppColors.inputFillDark.withValues(alpha: 0.55)
              : Colors.transparent,
          contentPadding: AppSizes.inputContentTall,
          enabledBorder: _border(),
          focusedBorder: _border(focused: true),
          disabledBorder: _border(),
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool focused = false}) {
    final color = hasError
        ? AppColors.error
        : focused
        ? AppColors.focus
        : AppColors.dividerDark;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      borderSide: BorderSide(color: color, width: hasError ? 2 : 1.5),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsanti fondo modalità modifica
// ---------------------------------------------------------------------------

class _ConfermaButton extends StatelessWidget {
  const _ConfermaButton({required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.p56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimaryDark,
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnDark,
                ),
              )
            : Text('Conferma', style: AppTextStyles.buttonCompact),
      ),
    );
  }
}

class _AnnullaEditButton extends StatelessWidget {
  const _AnnullaEditButton({required this.onPressed});

  final VoidCallback? onPressed;

  static const _red = Color(0xFFFF0202);
  static const _radius = BorderRadius.all(Radius.circular(AppSizes.radius16));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: AppColors.errorContainerDark,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: _red,
            ),
            borderRadius: _radius,
          ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: _red,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: _radius),
          ),
          child: Text(
            'Annulla',
            style: AppTextStyles.buttonCompact.copyWith(color: _red),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componenti schermata principale
// ---------------------------------------------------------------------------

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
  static const _fillTop = Color(0xFF6F4DBB);
  static const _fillBase = AppColors.brandPrimary;
  static const _fillBottom = Color(0xFF5228AD);

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
              Color.lerp(_fillTop, _fillBase, 0.15)!,
              _fillBase,
              _fillBottom,
            ],
            stops: const [0.0, 0.5, 1.0],
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

// ---------------------------------------------------------------------------
// Easter egg — popup dal basso con festoni
// ---------------------------------------------------------------------------

class _EasterEggSheet extends StatelessWidget {
  const _EasterEggSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1630),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/Icons/festoni.jpeg',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🎉 Hai trovato l\'easter egg! 🎉',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popup di conferma eliminazione account
// ---------------------------------------------------------------------------

class _EliminaAccountDialog extends StatefulWidget {
  const _EliminaAccountDialog();

  @override
  State<_EliminaAccountDialog> createState() => _EliminaAccountDialogState();
}

class _EliminaAccountDialogState extends State<_EliminaAccountDialog> {
  static const _red = Color(0xFFFF0202);
  static const _borderRadius = BorderRadius.all(Radius.circular(16));

  bool _isDeleting = false;
  String? _errorMessage;

  Future<void> _confermaEliminazione() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });
    try {
      await ApiProvider.account.deleteAccount();
      await SessionManager.clear();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        EliminaAccountSuccessScreen.routeName,
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = 'Eliminazione non riuscita. Riprova.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1630),
      shape: const RoundedRectangleBorder(
        borderRadius: _borderRadius,
        side: BorderSide(color: _red, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icona warning ────────────────────────────────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2A1F00),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD31A), width: 2),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFFD31A),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),

            // ── Titolo ───────────────────────────────────────────────────
            Text(
              'Elimina account?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // ── Avviso irreversibile ─────────────────────────────────────
            Text(
              'Azione irreversibile: i tuoi dati non potranno essere recuperati.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Pulsante Annulla (primario) ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7B55E0), Color(0xFF4A2BAE)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Annulla',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Link testuale Elimina account (secondario) ───────────────
            _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _red,
                    ),
                  )
                : GestureDetector(
                    onTap: _confermaEliminazione,
                    child: Text(
                      'Elimina comunque',
                      style: GoogleFonts.inter(
                        color: _red.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: _red.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
