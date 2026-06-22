import 'package:coincasa_app/data/models/salute_casa_item.dart';
import 'package:coincasa_app/data/models/turno.dart';

abstract interface class ITurniRepository {
  Future<List<Turno>> getTurni(String casaId);

  Future<List<Turno>> getTurniOggi(String casaId);

  Future<List<SaluteCasaItem>> getSaluteCasa(String casaId);

  Future<Turno> createTurno(String casaId, Map<String, dynamic> payload);

  Future<Turno> getTurnoById(String casaId, String idTurno);

  Future<Turno> updateTurno(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  );

  Future<void> deleteTurno(String casaId, String idTurno);

  Future<void> autoAssegnaTurno(String casaId, String idTurno);

  Future<void> assegnaTurno(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  );

  Future<void> toggleRotazioneTurno(String casaId, String idTurno);

  Future<void> completaTurno(String casaId, String idTurno);
}
