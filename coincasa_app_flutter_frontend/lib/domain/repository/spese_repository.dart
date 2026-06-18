import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';

abstract interface class SpeseRepository {
  Future<List<Spesa>> list(
    String casaId, {
    Map<String, String>? queryParameters,
  });

  Future<Spesa> getById(String casaId, String spesaId);

  Future<Spesa> create(String casaId, Map<String, dynamic> payload);

  Future<Spesa> update(
    String casaId,
    String spesaId,
    Map<String, dynamic> payload,
  );

  Future<void> delete(String casaId, String spesaId);

  Future<List<Quota>> getQuote(String casaId, String spesaId);

  Future<void> pagaQuota(String casaId, String spesaId, String quotaId);

  Future<void> pareggia(String casaId, List<String> idUtentiCreditori);

  Future<double> getSaldo(String casaId);

  Future<double> getCreditoTot(String casaId);

  Future<double> getDebitoTot(String casaId);

  Future<double> getCreditoVerso(String casaId, String inquilinoId);

  Future<double> getDebitoVerso(String casaId, String inquilinoId);
}
