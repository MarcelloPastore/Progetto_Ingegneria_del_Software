import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/data/service/spese_service.dart';
import 'package:coincasa_app/domain/repository/spese_repository.dart';

class SpeseRepositoryImpl implements SpeseRepository {
  const SpeseRepositoryImpl(this._service);

  final SpeseService _service;

  @override
  Future<List<Spesa>> list(
    String casaId, {
    Map<String, String>? queryParameters,
  }) {
    return _service.list(casaId, queryParameters: queryParameters);
  }

  @override
  Future<Spesa> getById(String casaId, String spesaId) {
    return _service.getById(casaId, spesaId);
  }

  @override
  Future<Spesa> create(String casaId, Map<String, dynamic> payload) {
    return _service.create(casaId, payload);
  }

  @override
  Future<Spesa> update(
    String casaId,
    String spesaId,
    Map<String, dynamic> payload,
  ) {
    return _service.update(casaId, spesaId, payload);
  }

  @override
  Future<void> delete(String casaId, String spesaId) {
    return _service.delete(casaId, spesaId);
  }

  @override
  Future<List<Quota>> getQuote(String casaId, String spesaId) {
    return _service.getQuote(casaId, spesaId);
  }

  @override
  Future<void> pagaQuota(String casaId, String spesaId, String quotaId) {
    return _service.pagaQuota(casaId, spesaId, quotaId);
  }

  @override
  Future<void> pareggia(String casaId, List<String> idUtentiCreditori) {
    return _service.pareggia(casaId, idUtentiCreditori);
  }

  @override
  Future<double> getSaldo(String casaId) {
    return _service.getSaldo(casaId);
  }

  @override
  Future<double> getCreditoTot(String casaId) {
    return _service.getCreditoTot(casaId);
  }

  @override
  Future<double> getDebitoTot(String casaId) {
    return _service.getDebitoTot(casaId);
  }

  @override
  Future<double> getCreditoVerso(String casaId, String inquilinoId) {
    return _service.getCreditoVerso(casaId, inquilinoId);
  }

  @override
  Future<double> getDebitoVerso(String casaId, String inquilinoId) {
    return _service.getDebitoVerso(casaId, inquilinoId);
  }
}
