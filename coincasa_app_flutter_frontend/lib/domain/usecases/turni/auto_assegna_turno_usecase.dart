import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class AutoAssegnaTurnoUseCase {
  const AutoAssegnaTurnoUseCase(this._repository);

  final ITurniRepository _repository;

  Future<void> call(String casaId, String idTurno) =>
      _repository.autoAssegnaTurno(casaId, idTurno);
}
