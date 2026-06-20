import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/domain/viewmodel/dashboard_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';
import 'package:coincasa_app/ui/casa/screens/compilazione_form_crea_casa.dart';
import 'package:coincasa_app/ui/casa/screens/entra_con_codice_invito_screen.dart';
import 'package:coincasa_app/ui/casa/screens/hub_casa_admin.dart';

class ListaCaseScreen extends ConsumerWidget {
  const ListaCaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(listaCaseViewModelProvider);
    final activeCasaState = ref.watch(activeCasaProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: vmAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _ErrorState(
              onRetry: () => ref.invalidate(listaCaseViewModelProvider),
            ),
            data: (caseUtente) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(caseCount: caseUtente.length),
                  const SizedBox(height: 20),
                  Expanded(
                    child: caseUtente.isEmpty
                        ? const Center(
                            child: Text(
                              'Nessuna casa attiva.',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(listaCaseViewModelProvider);
                              await ref.read(listaCaseViewModelProvider.future);
                            },
                            child: ListView.separated(
                              itemCount: caseUtente.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 20),
                              itemBuilder: (context, index) {
                                final casa = caseUtente[index];
                                final effectiveRuolo =
                                    casa.id == activeCasaState.selectedCasaId
                                        ? activeCasaState.ruoloCasa ??
                                              casa.ruolo
                                        : casa.ruolo;
                                return _HouseCard(
                                  casa: casa,
                                  effectiveRuolo: effectiveRuolo,
                                  onTap: () async {
                                    try {
                                      final ruolo = await ref
                                          .read(listaCaseViewModelProvider
                                              .notifier)
                                          .selectCasa(casa.id);
                                      ref
                                          .read(activeCasaProvider.notifier)
                                          .update(
                                            (s) => s.copyWith(
                                              selectedCasaId: casa.id,
                                              ruoloCasa: ruolo,
                                              selectedCasa: casa,
                                            ),
                                          );
                                      ref.invalidate(dashboardViewModelProvider);
                                    } catch (_) {}
                                    if (!context.mounted) return;
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            HubCasaAdminScreen(casaId: casa.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const CompilazioneFormCreaCasaScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aggiungi casa',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                    child: _OrDivider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: _InviteLinkButton(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EntraConCodiceInvitoScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Non e possibile caricare le case.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.caseCount});

  final int caseCount;

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
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/dashboard'),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Le mie case',
                style: AppTextStyles.dashboardHeaderTitle.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$caseCount ${caseCount == 1 ? 'casa attiva' : 'case attive'}',
                style: AppTextStyles.dashboardHeaderSubtitle.copyWith(
                  color: AppColors.brandAccent,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pushNamed('/account'),
          customBorder: const CircleBorder(),
          child: const _CurrentUserAvatar(),
        ),
      ],
    );
  }
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar();

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      radius: 26,
      userId: ApiProvider.client.currentUserAvatarSeed,
      username: ApiProvider.client.currentUserUsername,
    );
  }
}

class _HouseCard extends StatelessWidget {
  const _HouseCard({
    required this.casa,
    required this.effectiveRuolo,
    this.onTap,
  });

  final Casa casa;
  final String effectiveRuolo;
  final VoidCallback? onTap;

  String get _address {
    final parts = [
      casa.indirizzo,
      casa.citta,
    ].where((part) => part.trim().isNotEmpty).join(' - ');
    return parts.isEmpty ? 'Indirizzo non disponibile' : parts;
  }

  String get _role {
    if (effectiveRuolo == 'HomeAdmin' || effectiveRuolo == 'SysAdmin') {
      return 'Admin';
    }
    if (effectiveRuolo == 'Inquilino') {
      return 'Inquilino';
    }
    return 'Casa';
  }

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
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Image.asset(
                  'assets/Icons/appartamenti-moderni-lusso 1.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      casa.nome.isEmpty ? 'Casa senza nome' : casa.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _address,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
          padding: EdgeInsets.symmetric(horizontal: 11),
          child: Text(
            'oppure',
            style: TextStyle(
              color: AppColors.textMutedLight,
              fontSize: 15,
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

class _InviteLinkButton extends StatelessWidget {
  const _InviteLinkButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandAccent, width: 2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vpn_key, color: AppColors.keyYellow, size: 22),
              SizedBox(width: 12),
              Text(
                'Entra con link invito',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
