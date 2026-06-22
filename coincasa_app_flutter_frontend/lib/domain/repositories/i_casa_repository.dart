import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/domain/entities/hub_casa_aggregato.dart';

abstract interface class ICasaRepository {
  Future<List<Casa>> getCase();

  Future<Casa> getCasaById(String casaId);

  Future<Casa> createCasa(Map<String, dynamic> payload);

  Future<void> updateCasa(String casaId, Map<String, dynamic> payload);

  Future<void> deleteCasa(String casaId);

  Future<Casa> joinCasa(String inviteCodeOrLink);

  Future<String> selectCasa(String casaId);

  Future<HubCasaAggregato> getHub(String casaId);

  Future<List<Inquilino>> getInquilini(String casaId);

  Future<Inquilino> getInquilino(String casaId, String inquilinoId);

  Future<void> removeInquilino(String casaId, String inquilinoId);

  Future<void> updateRuoloInquilino(
    String casaId,
    String inquilinoId,
    Map<String, dynamic> payload,
  );

  Future<String> getInviteLink(String casaId);

  Future<String> regenerateInviteLink(String casaId);

  /// Rimuove l'utente corrente dalla casa (lascia casa).
  Future<void> lasciaCasa(String casaId, String currentUserId);
}
