import 'package:coincasa_app/data/models/turno.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class GetTurnoByIdUseCase {
  const GetTurnoByIdUseCase(this._repository);

  final ITurniRepository _repository;

  Future<Turno> call(String casaId, String idTurno) =>
      _repository.getTurnoById(casaId, idTurno);
}
