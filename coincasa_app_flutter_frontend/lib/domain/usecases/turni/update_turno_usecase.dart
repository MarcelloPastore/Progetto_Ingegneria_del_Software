import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class UpdateTurnoUseCase {
  const UpdateTurnoUseCase(this._repository);

  final ITurniRepository _repository;

  Future<Turno> call(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  ) => _repository.updateTurno(casaId, idTurno, payload);
}
