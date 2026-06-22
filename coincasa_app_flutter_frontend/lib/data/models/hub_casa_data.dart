import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/inquilino.dart';

class HubCasaData {
  const HubCasaData({
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
}
