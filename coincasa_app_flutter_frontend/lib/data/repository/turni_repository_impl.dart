import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/salute_casa_item.dart';
import 'package:coincasa_app/data/models/turno.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class TurniRepositoryImpl implements ITurniRepository {
  const TurniRepositoryImpl();

  @override
  Future<List<Turno>> getTurni(String casaId) {
    return ApiProvider.turni.list(casaId);
  }

  @override
  Future<List<Turno>> getTurniOggi(String casaId) {
    return ApiProvider.turni.listOggi(casaId);
  }

  @override
  Future<List<SaluteCasaItem>> getSaluteCasa(String casaId) {
    return ApiProvider.turni.saluteCase(casaId);
  }

  @override
  Future<Turno> createTurno(String casaId, Map<String, dynamic> payload) {
    return ApiProvider.turni.create(casaId, payload);
  }

  @override
  Future<Turno> getTurnoById(String casaId, String idTurno) {
    return ApiProvider.turni.getById(casaId, idTurno);
  }

  @override
  Future<Turno> updateTurno(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  ) {
    return ApiProvider.turni.update(casaId, idTurno, payload);
  }

  @override
  Future<void> deleteTurno(String casaId, String idTurno) {
    return ApiProvider.turni.delete(casaId, idTurno);
  }

  @override
  Future<void> autoAssegnaTurno(String casaId, String idTurno) {
    return ApiProvider.turni.autoAssegna(casaId, idTurno);
  }

  @override
  Future<void> assegnaTurno(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  ) {
    return ApiProvider.turni.assegna(casaId, idTurno, payload);
  }

  @override
  Future<void> toggleRotazioneTurno(String casaId, String idTurno) {
    return ApiProvider.turni.toggleRotazione(casaId, idTurno);
  }

  @override
  Future<void> completaTurno(String casaId, String idTurno) {
    return ApiProvider.turni.completa(casaId, idTurno);
  }
}
