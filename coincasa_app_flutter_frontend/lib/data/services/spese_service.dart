import 'package:coincasa_app/core/api/spese_api.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';

class SpeseService {
  const SpeseService(this._api);

  final SpeseApi _api;

  Future<List<Spesa>> getSpese(
    String casaId, {
    Map<String, String>? queryParameters,
  }) {
    return _api.list(casaId, queryParameters: queryParameters);
  }

  Future<Spesa> getSpesaById(String casaId, String idSpesa) {
    return _api.getById(casaId, idSpesa);
  }

  Future<Spesa> createSpesa(String casaId, Map<String, dynamic> payload) {
    return _api.create(casaId, payload);
  }

  Future<Spesa> updateSpesa(
    String casaId,
    String idSpesa,
    Map<String, dynamic> payload,
  ) {
    return _api.update(casaId, idSpesa, payload);
  }

  Future<void> deleteSpesa(String casaId, String idSpesa) {
    return _api.delete(casaId, idSpesa);
  }

  Future<List<Quota>> getQuoteSpesa(String casaId, String idSpesa) {
    return _api.getQuote(casaId, idSpesa);
  }

  Future<void> pagaQuota(String casaId, String idSpesa, String idQuota) {
    return _api.pagaQuota(casaId, idSpesa, idQuota);
  }

  Future<void> pareggiaConti(String casaId, List<String> idUtentiCreditori) {
    return _api.pareggia(casaId, idUtentiCreditori);
  }

  Future<double> getSaldo(String casaId) {
    return _api.getSaldo(casaId);
  }

  Future<double> getCreditoTotale(String casaId) {
    return _api.getCreditoTot(casaId);
  }

  Future<double> getDebitoTotale(String casaId) {
    return _api.getDebitoTot(casaId);
  }

  Future<double> getCreditoVerso(String casaId, String idInquilino) {
    return _api.getCreditoVerso(casaId, idInquilino);
  }

  Future<double> getDebitoVerso(String casaId, String idInquilino) {
    return _api.getDebitoVerso(casaId, idInquilino);
  }
}
