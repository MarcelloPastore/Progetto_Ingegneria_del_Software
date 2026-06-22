import 'package:coincasa_app/data/models/quota.dart';
import 'package:coincasa_app/data/models/spesa.dart';

abstract interface class ISpeseRepository {
  Future<List<Spesa>> getSpese(
    String casaId, {
    Map<String, String>? queryParameters,
  });

  Future<Spesa> getSpesaById(String casaId, String idSpesa);

  Future<Spesa> createSpesa(String casaId, Map<String, dynamic> payload);

  Future<Spesa> updateSpesa(
    String casaId,
    String idSpesa,
    Map<String, dynamic> payload,
  );

  Future<void> deleteSpesa(String casaId, String idSpesa);

  Future<List<Quota>> getQuoteSpesa(String casaId, String idSpesa);

  Future<void> pagaQuota(String casaId, String idSpesa, String idQuota);

  Future<void> pareggiaConti(String casaId, List<String> idUtentiCreditori);

  Future<double> getSaldo(String casaId);

  Future<double> getCreditoTotale(String casaId);

  Future<double> getDebitoTotale(String casaId);

  Future<double> getCreditoVerso(String casaId, String idInquilino);

  Future<double> getDebitoVerso(String casaId, String idInquilino);
}
