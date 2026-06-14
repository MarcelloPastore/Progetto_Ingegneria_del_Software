import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/features/casa/screens/compilazione_form_crea_casa.dart';
import 'package:coincasa_app/features/casa/screens/entra_con_codice_invito_screen.dart';

const _houseIllustration = 'assets/Icons/casa_colorata.png';

class CasaWelcomeScreen extends StatefulWidget {
  const CasaWelcomeScreen({
    super.key,
    required this.email,
    this.userId,
    this.username,
    this.firstName,
    this.lastName,
    this.displayName,
  });

  final String email;
  final String? userId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? displayName;

  @override
  State<CasaWelcomeScreen> createState() => _CasaWelcomeScreenState();
}

class _CasaWelcomeScreenState extends State<CasaWelcomeScreen> {
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final normalizedUsername = widget.username?.trim() ?? '';
    final normalizedName = widget.firstName?.trim() ?? '';
    final normalizedSurname = widget.lastName?.trim() ?? '';
    final normalizedDisplayName = widget.displayName?.trim() ?? '';

    if (normalizedUsername.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _userName = normalizedUsername;
        _isLoading = false;
      });
      ApiProvider.client.setCurrentUserIdentity(
        id: widget.userId,
        username: normalizedUsername,
        name: normalizedName,
        surname: normalizedSurname,
        displayName: normalizedDisplayName.isNotEmpty ? normalizedDisplayName : null,
      );
      return;
    }

    if (normalizedName.isNotEmpty || normalizedSurname.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _userName = [
          normalizedName,
          normalizedSurname,
        ].where((part) => part.isNotEmpty).join(' ');
        _isLoading = false;
      });
      ApiProvider.client.setCurrentUserIdentity(
        id: widget.userId,
        name: normalizedName,
        surname: normalizedSurname,
        displayName: normalizedDisplayName.isNotEmpty
            ? normalizedDisplayName
            : null,
      );
      return;
    }

    final normalizedEmail = widget.email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (_userName.isNotEmpty) {
      ApiProvider.client.setCurrentUserIdentity(displayName: _userName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _userName.isNotEmpty
        ? _userName
        : (_isLoading ? '...' : 'utente');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p25,
                      vertical: AppSizes.p24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Avatar → Gestione account ────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () =>
                                Navigator.of(context).pushNamed('/account'),
                            customBorder: const CircleBorder(),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFF1D254E),
                              child: Icon(
                                Icons.person_rounded,
                                color: AppColors.textOnDark,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.02),
                        Image.asset(
                          _houseIllustration,
                          width: 235,
                          height: 196,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppSizes.p13),
                        const Text(
                          'Benvenuto in CoinCasa!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p28),
                        _WelcomeInfoBox(userName: displayName),
                        const SizedBox(height: AppSizes.p16),
                        const Text(
                          'Crea la tua casa o entra in quella di un\ncoinquilino',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 16,
                            height: 1.18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p21),
                        _CasaActionButton(
                          icon: Icons.home_outlined,
                          text: 'Crea nuova casa',
                          filled: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const CompilazioneFormCreaCasaScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.p13),
                        const _OrDivider(),
                        const SizedBox(height: AppSizes.p13),
                        _CasaActionButton(
                          icon: Icons.vpn_key,
                          text: 'Entra con link invito',
                          filled: false,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const EntraConCodiceInvitoScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeInfoBox extends StatelessWidget {
  const _WelcomeInfoBox({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p15,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFillDark,
        borderRadius: BorderRadius.circular(AppSizes.radius15),
        border: Border.all(color: AppColors.inputBorderDark, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Ciao $userName!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          const Text(
            'Non sei ancora in nessuna casa condivisa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMutedLight,
              fontSize: 19,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CasaActionButton extends StatelessWidget {
  const _CasaActionButton({
    required this.icon,
    required this.text,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.brandSecondary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radius15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius15),
        child: Container(
          width: double.infinity,
          height: AppSizes.p56,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radius15),
            border: Border.all(
              color: filled ? AppColors.primaryBorder : AppColors.brandAccent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: filled ? AppColors.textMutedLight : AppColors.keyYellow,
                size: AppSizes.p25,
              ),
              const SizedBox(width: AppSizes.p16),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.inputBorderDark, thickness: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p11),
          child: Text(
            'oppure',
            style: TextStyle(
              color: AppColors.textMutedLight,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.inputBorderDark, thickness: 1),
        ),
      ],
    );
  }
}
