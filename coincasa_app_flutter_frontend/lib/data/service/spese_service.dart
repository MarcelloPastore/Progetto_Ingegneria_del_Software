import 'package:coincasa_app/core/api/spese_api.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';

class SpeseService {
  const SpeseService(this._api);

  final SpeseApi _api;

  Future<List<Spesa>> list(
    String casaId, {
    Map<String, String>? queryParameters,
  }) {
    return _api.list(casaId, queryParameters: queryParameters);
  }

  Future<Spesa> getById(String casaId, String spesaId) {
    return _api.getById(casaId, spesaId);
  }

  Future<Spesa> create(String casaId, Map<String, dynamic> payload) {
    return _api.create(casaId, payload);
  }

  Future<Spesa> update(
    String casaId,
    String spesaId,
    Map<String, dynamic> payload,
  ) {
    return _api.update(casaId, spesaId, payload);
  }

  Future<void> delete(String casaId, String spesaId) {
    return _api.delete(casaId, spesaId);
  }

  Future<List<Quota>> getQuote(String casaId, String spesaId) {
    return _api.getQuote(casaId, spesaId);
  }

  Future<void> pagaQuota(String casaId, String spesaId, String quotaId) {
    return _api.pagaQuota(casaId, spesaId, quotaId);
  }

  Future<void> pareggia(String casaId, List<String> idUtentiCreditori) {
    return _api.pareggia(casaId, idUtentiCreditori);
  }

  Future<double> getSaldo(String casaId) {
    return _api.getSaldo(casaId);
  }

  Future<double> getCreditoTot(String casaId) {
    return _api.getCreditoTot(casaId);
  }

  Future<double> getDebitoTot(String casaId) {
    return _api.getDebitoTot(casaId);
  }

  Future<double> getCreditoVerso(String casaId, String inquilinoId) {
    return _api.getCreditoVerso(casaId, inquilinoId);
  }

  Future<double> getDebitoVerso(String casaId, String inquilinoId) {
    return _api.getDebitoVerso(casaId, inquilinoId);
  }
}
