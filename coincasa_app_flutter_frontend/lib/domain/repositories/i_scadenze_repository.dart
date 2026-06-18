import 'package:coincasa_app/core/models/scadenza.dart';

abstract interface class IScadenzeRepository {
  Future<List<Scadenza>> getScadenze(String casaId);

  Future<Scadenza> getScadenzaById(String casaId, String idScadenza);

  Future<Scadenza> createScadenza(
    String casaId,
    Map<String, dynamic> payload,
  );

  Future<Scadenza> updateScadenza(
    String casaId,
    String idScadenza,
    Map<String, dynamic> payload,
  );

  Future<Scadenza> updateRicorrenza(
    String casaId,
    String idScadenza,
    Map<String, dynamic> payload,
  );

  Future<void> deleteScadenza(String casaId, String idScadenza);
}
