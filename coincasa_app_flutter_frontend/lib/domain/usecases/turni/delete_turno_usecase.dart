import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class DeleteTurnoUseCase {
  const DeleteTurnoUseCase(this._repository);

  final ITurniRepository _repository;

  Future<void> call(String casaId, String idTurno) =>
      _repository.deleteTurno(casaId, idTurno);
}
