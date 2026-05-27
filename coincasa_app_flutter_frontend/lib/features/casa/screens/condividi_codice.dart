import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coincasa_app/features/casa/screens/rigenera_link.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';

class CondividiCodiceScreen extends StatelessWidget {
  const CondividiCodiceScreen({super.key});

  static const List<BottomNavigationBarItem> _navigationItems = [
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/home.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/spese.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Spese',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/turni.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Turni',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/reminder.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Scadenze',
    ),
    BottomNavigationBarItem(
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Image(
          image: AssetImage('assets/Icons/problemi.png'),
          fit: BoxFit.contain,
        ),
      ),
      label: 'Problemi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09031F),
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF3F33B8),
              child: Image(
                image: AssetImage('assets/Icons/Profilo_utente_icona.png'),
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Padding(
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
                  SizedBox(height: 34),
                  _InviteCodeCard(),
                  SizedBox(height: 20),
                  _CopyButton(),
                  SizedBox(height: 24),
                  _RegenerateInfoCard(),
                  SizedBox(height: 26),
                  _RegenerateButton(),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 30,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: AppColors.brandAccent,
                foregroundColor: Colors.white,
                elevation: 5,
                child: const Icon(Icons.add, size: 32),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF17213B),
        selectedItemColor: const Color(0xFF28A8FF),
        unselectedItemColor: Colors.white,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        elevation: 8,
        items: _navigationItems,
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF17213B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9CA5DA), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Codice invito',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CopyIconButton(),
            ],
          ),
          const SizedBox(height: 14),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'CX-4821',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                letterSpacing: 5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Valido per 72 ore · rigenerabile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE5E7F5),
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'da Coinquilini > Invita',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFBFC4E6),
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyIconButton extends StatelessWidget {
  const _CopyIconButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copia codice',
      child: IconButton.filledTonal(
        onPressed: () {
          Clipboard.setData(const ClipboardData(text: 'CX-4821'));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Codice copiato')));
        },
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF2B2463),
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.brandAccent, width: 1.5),
          minimumSize: const Size(42, 42),
        ),
        icon: const Icon(Icons.copy_rounded, size: 22),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: () {
          Clipboard.setData(const ClipboardData(text: 'CX-4821'));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Codice copiato')));
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF9CA5DA), width: 2),
          ),
        ),
        child: const Text(
          'Copia Codice',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _RegenerateInfoCard extends StatelessWidget {
  const _RegenerateInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF17213B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9CA5DA), width: 2),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rigenera codice',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Genera un nuovo codice per invalidare quello precedente',
            style: TextStyle(
              color: Color(0xFFD2D4DF),
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegenerateButton extends StatelessWidget {
  const _RegenerateButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RigeneraLinkScreen()),
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF09031F),
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.brandAccent, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Rigenera link',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
