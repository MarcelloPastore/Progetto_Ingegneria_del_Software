import 'package:coincasa_app/core/models/salute_casa_item.dart';
import 'package:coincasa_app/core/models/turno.dart';

abstract interface class TurniRepository {
  Future<List<Turno>> list(String casaId);

  Future<List<Turno>> listOggi(String casaId);

  Future<List<SaluteCasaItem>> saluteCase(String casaId);

  Future<Turno> create(String casaId, Map<String, dynamic> payload);

  Future<Turno> getById(String casaId, String turnoId);

  Future<Turno> update(
    String casaId,
    String turnoId,
    Map<String, dynamic> payload,
  );

  Future<void> delete(String casaId, String turnoId);

  Future<void> autoAssegna(String casaId, String turnoId);

  Future<void> assegna(
    String casaId,
    String turnoId,
    Map<String, dynamic> payload,
  );

  Future<void> toggleRotazione(String casaId, String turnoId);

  Future<void> completa(String casaId, String turnoId);
}
