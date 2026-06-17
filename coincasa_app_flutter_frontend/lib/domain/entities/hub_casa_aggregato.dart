import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';

/// Dati aggregati restituiti dall'endpoint GET /case/:casaId/hub.
/// Include la casa con i suoi membri e i contatori di riepilogo.
class HubCasaAggregato {
  const HubCasaAggregato({
    required this.casa,
    required this.inquilini,
    required this.ruolo,
    required this.isCurrentUserOwner,
    this.speseCount = 0,
    this.scadenzeCount = 0,
    this.problemiCount = 0,
    this.turniCount = 0,
  });

  final Casa casa;
  final List<Inquilino> inquilini;
  final String ruolo;
  final bool isCurrentUserOwner;
  final int speseCount;
  final int scadenzeCount;
  final int problemiCount;
  final int turniCount;

  bool get isAdmin => ruolo == 'HomeAdmin' || ruolo == 'SysAdmin';

  factory HubCasaAggregato.fromMap(Map<String, dynamic> hub) {
    final casaJson = hub['casa'] as Map<String, dynamic>? ?? {};
    final casa = Casa.fromJson(casaJson);

    final membriJson = casaJson['membri'];
    final inquilini = (membriJson is List)
        ? membriJson
              .cast<Map<String, dynamic>>()
              .map(Inquilino.fromJson)
              .toList()
        : <Inquilino>[];

    final ruolo = hub['ruolo']?.toString() ?? '';
    final isOwner =
        hub['isOwner'] as bool? ?? hub['isCurrentUserOwner'] as bool?;
    final currentInquilino = inquilini.isNotEmpty
        ? inquilini
              .where((i) => i.isOwner)
              .cast<Inquilino?>()
              .firstOrNull
        : null;
    final isCurrentUserOwner = isOwner ?? currentInquilino?.isOwner ?? false;

    return HubCasaAggregato(
      casa: casa,
      inquilini: inquilini,
      ruolo: ruolo,
      isCurrentUserOwner: isCurrentUserOwner,
      speseCount: hub['speseCount'] as int? ?? 0,
      scadenzeCount: hub['scadenzeCount'] as int? ?? 0,
      problemiCount: hub['problemiCount'] as int? ?? 0,
      turniCount: hub['turniCount'] as int? ?? 0,
    );
  }
}
