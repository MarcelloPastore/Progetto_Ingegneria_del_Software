import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class CompletaTurnoUseCase {
  const CompletaTurnoUseCase(this._repository);

  final ITurniRepository _repository;

  Future<void> call(String casaId, String idTurno) =>
      _repository.completaTurno(casaId, idTurno);
}
