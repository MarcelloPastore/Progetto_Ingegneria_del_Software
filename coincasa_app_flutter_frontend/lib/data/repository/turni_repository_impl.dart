import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/salute_casa_item.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/data/services/turni_service.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class TurniRepositoryImpl implements ITurniRepository {
  const TurniRepositoryImpl(this._service);

  final TurniService _service;

  @override
  Future<List<Turno>> getTurni(String casaId) {
    return _service.getTurni(casaId);
  }

  @override
  Future<List<Turno>> getTurniOggi(String casaId) {
    return _service.getTurniOggi(casaId);
  }

  @override
  Future<List<SaluteCasaItem>> getSaluteCasa(String casaId) {
    return _service.getSaluteCasa(casaId);
  }

  @override
  Future<Turno> createTurno(String casaId, Map<String, dynamic> payload) {
    return _service.createTurno(casaId, payload);
  }

  @override
  Future<Turno> getTurnoById(String casaId, String idTurno) {
    return _service.getTurnoById(casaId, idTurno);
  }

  @override
  Future<Turno> updateTurno(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  ) {
    return _service.updateTurno(casaId, idTurno, payload);
  }

  @override
  Future<void> deleteTurno(String casaId, String idTurno) {
    return _service.deleteTurno(casaId, idTurno);
  }

  @override
  Future<void> autoAssegnaTurno(String casaId, String idTurno) {
    return _service.autoAssegnaTurno(casaId, idTurno);
  }

  @override
  Future<void> assegnaTurno(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  ) {
    return _service.assegnaTurno(casaId, idTurno, payload);
  }

  @override
  Future<void> toggleRotazioneTurno(String casaId, String idTurno) {
    return _service.toggleRotazioneTurno(casaId, idTurno);
  }

  @override
  Future<void> completaTurno(String casaId, String idTurno) {
    return _service.completaTurno(casaId, idTurno);
  }
}

final turniRepositoryProvider = Provider<ITurniRepository>(
  (_) => TurniRepositoryImpl(TurniService(ApiProvider.turni)),
);
