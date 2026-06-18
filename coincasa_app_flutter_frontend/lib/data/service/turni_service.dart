import 'package:coincasa_app/core/api/turni_api.dart';
import 'package:coincasa_app/core/models/salute_casa_item.dart';
import 'package:coincasa_app/core/models/turno.dart';

class TurniService {
  const TurniService(this._api);

  final TurniApi _api;

  Future<List<Turno>> list(String casaId) {
    return _api.list(casaId);
  }

  Future<List<Turno>> listOggi(String casaId) {
    return _api.listOggi(casaId);
  }

  Future<List<SaluteCasaItem>> saluteCase(String casaId) {
    return _api.saluteCase(casaId);
  }

  Future<Turno> create(String casaId, Map<String, dynamic> payload) {
    return _api.create(casaId, payload);
  }

  Future<Turno> getById(String casaId, String turnoId) {
    return _api.getById(casaId, turnoId);
  }

  Future<Turno> update(
    String casaId,
    String turnoId,
    Map<String, dynamic> payload,
  ) {
    return _api.update(casaId, turnoId, payload);
  }

  Future<void> delete(String casaId, String turnoId) {
    return _api.delete(casaId, turnoId);
  }

  Future<void> autoAssegna(String casaId, String turnoId) {
    return _api.autoAssegna(casaId, turnoId);
  }

  Future<void> assegna(
    String casaId,
    String turnoId,
    Map<String, dynamic> payload,
  ) {
    return _api.assegna(casaId, turnoId, payload);
  }

  Future<void> toggleRotazione(String casaId, String turnoId) {
    return _api.toggleRotazione(casaId, turnoId);
  }

  Future<void> completa(String casaId, String turnoId) {
    return _api.completa(casaId, turnoId);
  }
}
