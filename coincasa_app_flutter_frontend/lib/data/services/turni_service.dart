import 'package:coincasa_app/core/api/turni_api.dart';
import 'package:coincasa_app/core/models/salute_casa_item.dart';
import 'package:coincasa_app/core/models/turno.dart';

class TurniService {
  const TurniService(this._api);

  final TurniApi _api;

  Future<List<Turno>> getTurni(String casaId) {
    return _api.list(casaId);
  }

  Future<List<Turno>> getTurniOggi(String casaId) {
    return _api.listOggi(casaId);
  }

  Future<List<SaluteCasaItem>> getSaluteCasa(String casaId) {
    return _api.saluteCase(casaId);
  }

  Future<Turno> createTurno(String casaId, Map<String, dynamic> payload) {
    return _api.create(casaId, payload);
  }

  Future<Turno> getTurnoById(String casaId, String idTurno) {
    return _api.getById(casaId, idTurno);
  }

  Future<Turno> updateTurno(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  ) {
    return _api.update(casaId, idTurno, payload);
  }

  Future<void> deleteTurno(String casaId, String idTurno) {
    return _api.delete(casaId, idTurno);
  }

  Future<void> autoAssegnaTurno(String casaId, String idTurno) {
    return _api.autoAssegna(casaId, idTurno);
  }

  Future<void> assegnaTurno(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  ) {
    return _api.assegna(casaId, idTurno, payload);
  }

  Future<void> toggleRotazioneTurno(String casaId, String idTurno) {
    return _api.toggleRotazione(casaId, idTurno);
  }

  Future<void> completaTurno(String casaId, String idTurno) {
    return _api.completa(casaId, idTurno);
  }
}
