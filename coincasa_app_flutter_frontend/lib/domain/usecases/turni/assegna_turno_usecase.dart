import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class AssegnaTurnoUseCase {
  const AssegnaTurnoUseCase(this._repository);

  final ITurniRepository _repository;

  Future<void> call(
    String casaId,
    String idTurno,
    Map<String, dynamic> payload,
  ) => _repository.assegnaTurno(casaId, idTurno, payload);
}
