import 'package:coincasa_app/core/models/salute_casa_item.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/data/service/turni_service.dart';
import 'package:coincasa_app/domain/repository/turni_repository.dart';

class TurniRepositoryImpl implements TurniRepository {
  const TurniRepositoryImpl(this._service);

  final TurniService _service;

  @override
  Future<List<Turno>> list(String casaId) {
    return _service.list(casaId);
  }

  @override
  Future<List<Turno>> listOggi(String casaId) {
    return _service.listOggi(casaId);
  }

  @override
  Future<List<SaluteCasaItem>> saluteCase(String casaId) {
    return _service.saluteCase(casaId);
  }

  @override
  Future<Turno> create(String casaId, Map<String, dynamic> payload) {
    return _service.create(casaId, payload);
  }

  @override
  Future<Turno> getById(String casaId, String turnoId) {
    return _service.getById(casaId, turnoId);
  }

  @override
  Future<Turno> update(
    String casaId,
    String turnoId,
    Map<String, dynamic> payload,
  ) {
    return _service.update(casaId, turnoId, payload);
  }

  @override
  Future<void> delete(String casaId, String turnoId) {
    return _service.delete(casaId, turnoId);
  }

  @override
  Future<void> autoAssegna(String casaId, String turnoId) {
    return _service.autoAssegna(casaId, turnoId);
  }

  @override
  Future<void> assegna(
    String casaId,
    String turnoId,
    Map<String, dynamic> payload,
  ) {
    return _service.assegna(casaId, turnoId, payload);
  }

  @override
  Future<void> toggleRotazione(String casaId, String turnoId) {
    return _service.toggleRotazione(casaId, turnoId);
  }

  @override
  Future<void> completa(String casaId, String turnoId) {
    return _service.completa(casaId, turnoId);
  }
}
