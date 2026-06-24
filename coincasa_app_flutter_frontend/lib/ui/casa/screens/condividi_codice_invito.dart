import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';

class CondividiCodiceScreen extends ConsumerStatefulWidget {
  const CondividiCodiceScreen({super.key, required this.casaId});

  final String casaId;

  @override
  ConsumerState<CondividiCodiceScreen> createState() =>
      _CondividiCodiceScreenState();
}

class _CondividiCodiceScreenState extends ConsumerState<CondividiCodiceScreen> {
  late Future<String> _inviteLinkFuture;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _inviteLinkFuture =
        ref.read(casaRepositoryProvider).getInviteLink(widget.casaId);
  }

  void _reload() {
    setState(() {
      _inviteLinkFuture =
          ref.read(casaRepositoryProvider).getInviteLink(widget.casaId);
    });
  }

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    try {
      final newLink = await ref
          .read(casaRepositoryProvider)
          .regenerateInviteLink(widget.casaId);
      if (!mounted) return;
      setState(() {
        _inviteLinkFuture = Future.value(newLink);
        _regenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link rigenerato con successo')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _regenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante la rigenerazione del link')),
      );
    }
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.textOnDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: AppSizes.p22),
          onPressed: Navigator.of(context).pop,
        ),
        title: const Text(
          'Invita coinquilino',
          style: TextStyle(
            fontSize: AppSizes.p20,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDark,
          ),
        ),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.p16),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed('/account'),
              customBorder: const CircleBorder(),
              child: UserAvatar(
                radius: 18,
                userId: ApiProvider.client.currentUserAvatarSeed,
                username: ApiProvider.client.currentUserUsername,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _inviteLinkFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _InviteErrorState(onRetry: _reload);
            }

            final inviteLink = snapshot.data ?? '';
            final inviteCode = _extractInviteCode(inviteLink);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p24,
                AppSizes.p26,
                AppSizes.p24,
                AppSizes.p132,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.p10),
                    child: Text(
                      'Condividi il codice o link per aggiungere un nuovo coinquilino',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: AppSizes.p18,
                        height: AppSizes.p1_2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p34),
                  _InviteCodeCard(
                    inviteCode: inviteCode,
                    onCopy: () => _copy(inviteCode, 'Codice copiato'),
                  ),
                  const SizedBox(height: AppSizes.p20),
                  _CopyButton(
                    label: 'Copia codice',
                    onPressed: () => _copy(inviteCode, 'Codice copiato'),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  _CopyButton(
                    label: 'Copia link',
                    onPressed: () => _copy(inviteLink, 'Link copiato'),
                  ),
                  const SizedBox(height: AppSizes.p24),
                  _RegenerateButton(
                    onPressed: _regenerating ? null : _regenerate,
                    loading: _regenerating,
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const HouseQuickNav(currentRoute: '/dashboard'),
    );
  }

  String _extractInviteCode(String inviteLink) {
    final trimmed = inviteLink.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final separatorIndex = trimmed.lastIndexOf('/');
    if (separatorIndex == -1 || separatorIndex == trimmed.length - 1) {
      return trimmed;
    }
    return trimmed.substring(separatorIndex + 1);
  }
}

class _InviteErrorState extends StatelessWidget {
  const _InviteErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: AppColors.textOnDark, size: AppSizes.p42),
          const SizedBox(height: AppSizes.p12),
          const Text(
            'Non è possibile caricare il codice invito.',
            style: TextStyle(color: AppColors.textOnDark),
          ),
          const SizedBox(height: AppSizes.p16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.inviteCode, required this.onCopy});

  final String inviteCode;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p18,
        AppSizes.p14,
        AppSizes.p18,
        AppSizes.p18,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSizes.radius14),
        border: Border.all(color: AppColors.inviteCardBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Codice invito',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: AppSizes.p18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Tooltip(
                message: 'Copia codice',
                child: IconButton.filledTonal(
                  onPressed: onCopy,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceDarkMuted,
                    foregroundColor: AppColors.textOnDark,
                    side: const BorderSide(
                      color: AppColors.brandAccent,
                      width: 1.5,
                    ),
                    minimumSize: const Size(AppSizes.p42, AppSizes.p42),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: AppSizes.p22),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              inviteCode,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: AppSizes.p34,
                letterSpacing: 5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p14),
          const Text(
            'Codice attivo della casa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.inviteSubtitleText,
              fontSize: AppSizes.p14,
              height: AppSizes.p1_2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.p54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.textOnDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius14),
            side: const BorderSide(color: AppColors.inviteCardBorder, width: 2),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: AppSizes.p22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RegenerateButton extends StatelessWidget {
  const _RegenerateButton({required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return SizedBox(
      height: AppSizes.p56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.textOnDark,
          disabledForegroundColor: AppColors.textOnDark.withValues(alpha: 0.54),
          side: BorderSide(
            color: isEnabled
                ? AppColors.brandAccent
                : AppColors.textOnDark.withValues(alpha: 0.24),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: AppSizes.p24,
                height: AppSizes.p24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textOnDarkMuted,
                ),
              )
            : const Text(
                'Rigenera link',
                style: TextStyle(
                  fontSize: AppSizes.p22,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
