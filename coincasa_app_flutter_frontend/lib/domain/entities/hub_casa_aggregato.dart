import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/domain/value_objects/ruolo_casa.dart';

/// Dati aggregati restituiti dall'endpoint GET /case/:casaId/hub.
/// Include la casa con i suoi membri e i contatori di riepilogo.
/// La deserializzazione JSON è responsabilità di CasaRepositoryImpl.
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

  bool get isAdmin => RuoloCasa.isAdmin(ruolo);
}
