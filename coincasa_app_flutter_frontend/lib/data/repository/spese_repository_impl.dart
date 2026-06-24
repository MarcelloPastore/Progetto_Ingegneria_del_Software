import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/quota.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class SpeseRepositoryImpl implements ISpeseRepository {
  const SpeseRepositoryImpl();

  @override
  Future<List<Spesa>> getSpese(
    String casaId, {
    Map<String, String>? queryParameters,
  }) {
    return ApiProvider.spese.list(casaId, queryParameters: queryParameters);
  }

  @override
  Future<Spesa> getSpesaById(String casaId, String idSpesa) {
    return ApiProvider.spese.getById(casaId, idSpesa);
  }

  @override
  Future<Spesa> createSpesa(String casaId, Map<String, dynamic> payload) {
    return ApiProvider.spese.create(casaId, payload);
  }

  @override
  Future<Spesa> updateSpesa(
    String casaId,
    String idSpesa,
    Map<String, dynamic> payload,
  ) {
    return ApiProvider.spese.update(casaId, idSpesa, payload);
  }

  @override
  Future<void> deleteSpesa(String casaId, String idSpesa) {
    return ApiProvider.spese.delete(casaId, idSpesa);
  }

  @override
  Future<List<Quota>> getQuoteSpesa(String casaId, String idSpesa) {
    return ApiProvider.spese.getQuote(casaId, idSpesa);
  }

  @override
  Future<void> pagaQuota(String casaId, String idSpesa, String idQuota) {
    return ApiProvider.spese.pagaQuota(casaId, idSpesa, idQuota);
  }

  @override
  Future<void> pareggiaConti(String casaId, List<String> idUtentiCreditori) {
    return ApiProvider.spese.pareggia(casaId, idUtentiCreditori);
  }

  @override
  Future<double> getSaldo(String casaId) {
    return ApiProvider.spese.getSaldo(casaId);
  }

  @override
  Future<double> getCreditoTotale(String casaId) {
    return ApiProvider.spese.getCreditoTot(casaId);
  }

  @override
  Future<double> getDebitoTotale(String casaId) {
    return ApiProvider.spese.getDebitoTot(casaId);
  }

  @override
  Future<double> getCreditoVerso(String casaId, String idInquilino) {
    return ApiProvider.spese.getCreditoVerso(casaId, idInquilino);
  }

  @override
  Future<double> getDebitoVerso(String casaId, String idInquilino) {
    return ApiProvider.spese.getDebitoVerso(casaId, idInquilino);
  }
}
