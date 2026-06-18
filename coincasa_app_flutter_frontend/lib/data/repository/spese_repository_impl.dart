import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/data/services/spese_service.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class SpeseRepositoryImpl implements ISpeseRepository {
  const SpeseRepositoryImpl(this._service);

  final SpeseService _service;

  @override
  Future<List<Spesa>> getSpese(
    String casaId, {
    Map<String, String>? queryParameters,
  }) {
    return _service.getSpese(casaId, queryParameters: queryParameters);
  }

  @override
  Future<Spesa> getSpesaById(String casaId, String idSpesa) {
    return _service.getSpesaById(casaId, idSpesa);
  }

  @override
  Future<Spesa> createSpesa(String casaId, Map<String, dynamic> payload) {
    return _service.createSpesa(casaId, payload);
  }

  @override
  Future<Spesa> updateSpesa(
    String casaId,
    String idSpesa,
    Map<String, dynamic> payload,
  ) {
    return _service.updateSpesa(casaId, idSpesa, payload);
  }

  @override
  Future<void> deleteSpesa(String casaId, String idSpesa) {
    return _service.deleteSpesa(casaId, idSpesa);
  }

  @override
  Future<List<Quota>> getQuoteSpesa(String casaId, String idSpesa) {
    return _service.getQuoteSpesa(casaId, idSpesa);
  }

  @override
  Future<void> pagaQuota(String casaId, String idSpesa, String idQuota) {
    return _service.pagaQuota(casaId, idSpesa, idQuota);
  }

  @override
  Future<void> pareggiaConti(String casaId, List<String> idUtentiCreditori) {
    return _service.pareggiaConti(casaId, idUtentiCreditori);
  }

  @override
  Future<double> getSaldo(String casaId) {
    return _service.getSaldo(casaId);
  }

  @override
  Future<double> getCreditoTotale(String casaId) {
    return _service.getCreditoTotale(casaId);
  }

  @override
  Future<double> getDebitoTotale(String casaId) {
    return _service.getDebitoTotale(casaId);
  }

  @override
  Future<double> getCreditoVerso(String casaId, String idInquilino) {
    return _service.getCreditoVerso(casaId, idInquilino);
  }

  @override
  Future<double> getDebitoVerso(String casaId, String idInquilino) {
    return _service.getDebitoVerso(casaId, idInquilino);
  }
}

final speseRepositoryProvider = Provider<ISpeseRepository>(
  (_) => SpeseRepositoryImpl(SpeseService(ApiProvider.spese)),
);
