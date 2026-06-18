import 'package:coincasa_app/core/models/problema.dart';

abstract interface class IProblemiRepository {
  Future<List<Problema>> getProblemi(String casaId);

  Future<List<Problema>> getProblemiNonRisolti(String casaId);

  Future<Problema> getProblemaById(String casaId, String problemaId);

  Future<Problema> createProblema(
    String casaId,
    Map<String, dynamic> payload,
  );

  Future<Problema> updateProblema(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  );

  Future<void> deleteProblema(String casaId, String problemaId);

  Future<Problema> autoAssegnaProblema(String casaId, String problemaId);

  Future<Problema> rinunciaProblema(String casaId, String problemaId);

  Future<Problema> assegnaProblema(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  );

  /// [payload] deve contenere `{'stato': StatoProblema.*}`.
  Future<Problema> aggiornaStatoProblema(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  );

  /// [payload] deve contenere `{'priorita': PrioritaProblema.*}`.
  Future<Problema> aggiornaPrioritaProblema(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  );
}
