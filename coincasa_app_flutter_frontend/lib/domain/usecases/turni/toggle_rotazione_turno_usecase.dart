import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class ToggleRotazioneTurnoUseCase {
  const ToggleRotazioneTurnoUseCase(this._repository);

  final ITurniRepository _repository;

  Future<void> call(String casaId, String idTurno) =>
      _repository.toggleRotazioneTurno(casaId, idTurno);
}
