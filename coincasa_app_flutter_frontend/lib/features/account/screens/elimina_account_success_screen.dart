import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/pending_debts_banner.dart';

class EliminaAccountSuccessScreen extends StatefulWidget {
  const EliminaAccountSuccessScreen({super.key});

  static const routeName = '/account/eliminato';

  @override
  State<EliminaAccountSuccessScreen> createState() =>
      _EliminaAccountSuccessScreenState();
}

class _EliminaAccountSuccessScreenState
    extends State<EliminaAccountSuccessScreen> {
  late final Future<List<Spesa>> _spesePendentiFuture;

  @override
  void initState() {
    super.initState();
    _spesePendentiFuture = _loadSpesePendenti();
  }

  Future<List<Spesa>> _loadSpesePendenti() async {
    try {
      final caseUtente = await ApiProvider.casa.list();
      final userId = ApiProvider.client.currentUserId;
      final userEmail = ApiProvider.client.currentUserEmail;
      final pendenti = <Spesa>[];

      for (final casa in caseUtente) {
        final spese = await ApiProvider.spese.list(casa.id);
        for (final spesa in spese) {
          final isAnticipataAltri =
              _hasAnticipatore(spesa.raw) &&
              (userId == null || spesa.creatoreId != userId);
          if (!isAnticipataAltri) continue;

          final nonEsclusi = spesa.partecipanti.where(
            (p) => p['escluso'] != true,
          );
          for (final p in nonEsclusi) {
            if (_isCurrentUser(p, userId, userEmail)) {
              final pagato =
                  p['pagato'] == true ||
                  p['pagata'] == true ||
                  p['saldato'] == true;
              if (!pagato) {
                pendenti.add(spesa);
              }
              break;
            }
          }
        }
      }
      return pendenti;
    } catch (_) {
      return [];
    }
  }

  static bool _isCurrentUser(
    Map<String, dynamic> p,
    String? userId,
    String? userEmail,
  ) {
    final utente = p['utente'];
    if (utente is Map) {
      if (userId != null &&
          (utente['id']?.toString() == userId ||
              utente['utenteId']?.toString() == userId)) {
        return true;
      }
      if (userEmail != null &&
          utente['email']?.toString().toLowerCase() == userEmail) {
        return true;
      }
    }
    if (userId != null &&
        (p['utenteId']?.toString() == userId ||
            p['idUtente']?.toString() == userId)) {
      return true;
    }
    if (userEmail != null &&
        p['email']?.toString().toLowerCase() == userEmail) {
      return true;
    }
    return false;
  }

  static bool _hasAnticipatore(Map<String, dynamic> raw) {
    final anticipataDa = raw['anticipataDa'];
    if (anticipataDa != null && anticipataDa.toString().trim().isNotEmpty) {
      return true;
    }
    final pagatore = raw['pagatore'];
    if (pagatore is Map && pagatore.isNotEmpty) return true;
    if (pagatore is String && pagatore.trim().isNotEmpty) return true;
    final pagatoreNome = raw['pagatoreNome'] ?? raw['pagatoDa'];
    if (pagatoreNome != null && pagatoreNome.toString().trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: FutureBuilder<List<Spesa>>(
            future: _spesePendentiFuture,
            builder: (context, snapshot) {
              final spesePendenti = snapshot.data ?? [];
              final hasPendenti = spesePendenti.isNotEmpty;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.errorStrong,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.errorStrong,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Hai eliminato il tuo account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainerDark,
                              border: Border.all(
                                color: AppColors.errorStrong,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'I tuoi dati sono stati resi anonimi.\nOra puoi tornare alla schermata di Login.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFFFB3B3),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),

                          if (hasPendenti) ...[
                            const SizedBox(height: 16),
                            PendingDebtsBanner(spese: spesePendenti),
                          ],
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.brandSecondary,
                              AppColors.brandPrimaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowOverlay,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (_) => false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Torna al Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
