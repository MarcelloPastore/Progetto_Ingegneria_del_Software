import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'package:coincasa_app/core/widgets/common/user_avatar.dart';

class CondividiCodiceScreen extends StatefulWidget {
  const CondividiCodiceScreen({super.key, required this.casaId});

  final String casaId;

  @override
  State<CondividiCodiceScreen> createState() => _CondividiCodiceScreenState();
}

class _CondividiCodiceScreenState extends State<CondividiCodiceScreen> {
  late Future<String> _inviteLinkFuture;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _inviteLinkFuture = ApiProvider.casa.getInviteLink(widget.casaId);
  }

  void _reload() {
    setState(() {
      _inviteLinkFuture = ApiProvider.casa.getInviteLink(widget.casaId);
    });
  }

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    try {
      final newLink = await ApiProvider.casa.regenerateInviteLink(widget.casaId);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
          'Invita coinquilino',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Condividi il codice o link per aggiungere un nuovo coinquilino',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  _InviteCodeCard(
                    inviteCode: inviteCode,
                    onCopy: () => _copy(inviteCode, 'Codice copiato'),
                  ),
                  const SizedBox(height: 20),
                  _CopyButton(
                    label: 'Copia codice',
                    onPressed: () => _copy(inviteCode, 'Codice copiato'),
                  ),
                  const SizedBox(height: 12),
                  _CopyButton(
                    label: 'Copia link',
                    onPressed: () => _copy(inviteLink, 'Link copiato'),
                  ),
                  const SizedBox(height: 24),
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
          const Icon(Icons.wifi_off, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Non e possibile caricare il codice invito.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9CA5DA), width: 2),
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
                    color: Colors.white,
                    fontSize: 18,
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
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: AppColors.brandAccent,
                      width: 1.5,
                    ),
                    minimumSize: const Size(42, 42),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              inviteCode,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                letterSpacing: 5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Codice attivo della casa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE5E7F5),
              fontSize: 14,
              height: 1.2,
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
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF9CA5DA), width: 2),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          side: BorderSide(
            color: onPressed != null ? AppColors.brandAccent : Colors.white24,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white54,
                ),
              )
            : const Text(
                'Rigenera link',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
