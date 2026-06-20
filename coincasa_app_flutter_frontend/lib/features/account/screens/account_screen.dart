import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_client.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/providers/theme_provider.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';
import 'package:coincasa_app/domain/viewmodel/account_view_model.dart';
import 'package:coincasa_app/features/account/screens/elimina_account_success_screen.dart';
import 'package:coincasa_app/features/account/screens/modifica_password_screen.dart';
import 'package:coincasa_app/features/auth/screens/check_email_screen.dart';

class GestioneAccountScreen extends ConsumerStatefulWidget {
  const GestioneAccountScreen({super.key});

  static const routeName = '/account';

  @override
  ConsumerState<GestioneAccountScreen> createState() =>
      _GestioneAccountScreenState();
}

class _GestioneAccountScreenState extends ConsumerState<GestioneAccountScreen> {
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
      await ref.read(accountViewModelProvider.notifier).patchUsername(newUsername);
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
      final confirmedEmail =
          await ref.read(accountViewModelProvider.notifier).patchEmail(newEmail);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final client = ApiProvider.client;
    final displayName = client.currentUserUsername ?? 'Utente';
    final email = client.currentUserEmail ?? 'email@esempio.com';
    final username = client.currentUserUsername ?? displayName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_isEditingUsername) {
                        _cancelEditUsername();
                      } else if (_isEditingEmail) {
                        _cancelEditEmail();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/dashboard');
                      }
                    },
                  ),
                ),
              ),

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
                        style: TextStyle(
                          color: colorScheme.onSurface,
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DATI ACCOUNT',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              _AccountRow(
                                label: 'Nome utente',
                                value: displayName,
                                onModifica: _startEditUsername,
                              ),
                              _AccountDivider(color: colorScheme.outlineVariant),
                              _AccountRow(
                                label: 'Email',
                                value: email,
                                onModifica: _startEditEmail,
                              ),
                              _AccountDivider(color: colorScheme.outlineVariant),
                              _AccountRow(
                                label: 'Password',
                                value: '••••••••',
                                onModifica: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const ModificaPasswordScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'PREFERENZE',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const _ThemeSelectorRow(),
                        ),
                        const SizedBox(height: 20),

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

              if (_isEditingUsername) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: _ConfermaButton(
                    isLoading: _isConfirming,
                    onPressed: _isConfirming
                        ? null
                        : () => _confirmEditUsername(username),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 52, 24),
                  child: AppCancelButton(
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
                        : () => _confirmEditEmail(email),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 52, 24),
                  child: AppCancelButton(
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
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

// ---------------------------------------------------------------------------
// Riga tema con toggle animato sole/luna
// ---------------------------------------------------------------------------

class _ThemeSelectorRow extends ConsumerWidget {
  const _ThemeSelectorRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tema',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const _AnimatedThemeToggle(),
        ],
      ),
    );
  }
}

// Toggle animato sole ↔ luna con spring physics
class _AnimatedThemeToggle extends ConsumerStatefulWidget {
  const _AnimatedThemeToggle();

  @override
  ConsumerState<_AnimatedThemeToggle> createState() =>
      _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends ConsumerState<_AnimatedThemeToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  // Traccia l'ultimo ThemeMode sincronizzato per gestire cambi esterni
  ThemeMode? _lastSynced;

  static const _w = 148.0;
  static const _h = 52.0;
  static const _thumbSize = 44.0;
  static const _margin = 4.0;

  // Half-range di alignment: (containerW/2 - thumbW/2 - margin) / (containerW/2)
  static const _alignRange =
      (_w / 2 - _thumbSize / 2 - _margin) / (_w / 2); // ≈ 0.905

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    );
    _anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
      reverseCurve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isDark(ThemeMode mode) {
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  void _toggle() {
    final dark = _isDark(ref.read(themeProvider));
    HapticFeedback.lightImpact();
    if (dark) {
      _controller.reverse();
      ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
    } else {
      _controller.forward();
      ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    // Sincronizza il controller ad ogni cambio esterno (es. caricamento da prefs)
    if (_lastSynced != themeMode && !_controller.isAnimating) {
      _lastSynced = themeMode;
      _controller.value = _isDark(themeMode) ? 1.0 : 0.0;
    }

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value; // può andare leggermente fuori [0,1] per l'overshoot
          final tC = t.clamp(0.0, 1.0); // usato solo per colori

          final bgColor = Color.lerp(
            const Color(0xFFFFF8E7), // caldo diurno
            const Color(0xFF0B0820), // profondo notturno
            tC,
          )!;
          final borderColor = Color.lerp(
            const Color(0xFFFFD54F), // amber
            AppColors.brandPrimary,
            tC,
          )!;
          final glowColor = Color.lerp(
            const Color(0xFFFFD54F).withValues(alpha: 0.35),
            AppColors.brandPrimary.withValues(alpha: 0.40),
            tC,
          )!;
          final thumbColor = Color.lerp(
            Colors.white,
            AppColors.brandSecondary,
            tC,
          )!;
          final thumbAlign = -_alignRange + t * 2 * _alignRange;

          return Container(
            width: _w,
            height: _h,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_h / 2),
              color: bgColor,
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // ── Sole (sinistra) ───────────────────────────────────────
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _w / 2,
                  child: Center(
                    child: Opacity(
                      opacity: (1.0 - tC * 1.6).clamp(0.2, 1.0),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        color: Color(0xFFFFB300),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // ── Luna (destra) ─────────────────────────────────────────
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: _w / 2,
                  child: Center(
                    child: Opacity(
                      opacity: (tC * 1.6 - 0.2).clamp(0.2, 1.0),
                      child: Icon(
                        Icons.nightlight_round,
                        color: Color.lerp(
                          AppColors.brandAccent.withValues(alpha: 0.3),
                          AppColors.brandAccent,
                          tC,
                        ),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                // ── Thumb scorrevole ──────────────────────────────────────
                Align(
                  alignment: Alignment(thumbAlign, 0),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumbColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.10 + tC * 0.14,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          tC > 0.5
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          key: ValueKey(tC > 0.5),
                          color: tC > 0.5
                              ? Colors.white
                              : const Color(0xFFFF8F00),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pannello modifica campo generico (username / email)
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
        _InlineField(
          value: currentValue,
          tag: 'Attuale',
          tagColor: AppColors.keyYellow,
          readOnly: true,
        ),
        const SizedBox(height: 10),
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
    final ctrl = readOnly
        ? TextEditingController(text: value ?? '')
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
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          suffix: Text(
            tag,
            style: TextStyle(
              color: tagColor,
              fontSize: 13,
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
// Pulsante Conferma
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

// ---------------------------------------------------------------------------
// Riga account (label + valore + pulsante modifica)
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
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
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onModifica,
                child: Text(
                  'Modifica',
                  style: TextStyle(
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
  const _AccountDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: color,
      indent: 16,
      endIndent: 16,
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsante Logout
// ---------------------------------------------------------------------------

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _radius = BorderRadius.all(Radius.circular(12));

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
              AppColors.brandSecondary,
              AppColors.brandPrimary,
              AppColors.brandPrimaryDark,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: AppColors.brandAccent,
            ),
            borderRadius: _radius,
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadowOverlay,
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
          label: const Text(
            'Logout',
            style: TextStyle(
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

// ---------------------------------------------------------------------------
// Pulsante Elimina account
// ---------------------------------------------------------------------------

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
          gradient: AppGradients.whiteOverlay(),
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
              color: AppColors.shadowOverlay,
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
          label: const Text(
            'Elimina account',
            style: TextStyle(
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
// Easter egg
// ---------------------------------------------------------------------------

class _EasterEggSheet extends StatelessWidget {
  const _EasterEggSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowHeavy,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
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
          const Text(
            '🎉 Hai trovato l\'easter egg! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
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
// Dialog conferma eliminazione account
// ---------------------------------------------------------------------------

class _EliminaAccountDialog extends ConsumerStatefulWidget {
  const _EliminaAccountDialog();

  @override
  ConsumerState<_EliminaAccountDialog> createState() =>
      _EliminaAccountDialogState();
}

class _EliminaAccountDialogState extends ConsumerState<_EliminaAccountDialog> {
  static const _red = AppColors.errorStrong;
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
      await ref.read(accountViewModelProvider.notifier).deleteAccount();
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
      backgroundColor: AppColors.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: _borderRadius,
        side: BorderSide(color: _red, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.warningCircleDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.keyYellow, width: 2),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.keyYellow,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Elimina account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Azione irreversibile: i tuoi dati non potranno essere recuperati.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                style: const TextStyle(
                  color: _red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.brandSecondary, AppColors.brandPrimaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowOverlay,
                      blurRadius: 4,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

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
                      style: TextStyle(
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
