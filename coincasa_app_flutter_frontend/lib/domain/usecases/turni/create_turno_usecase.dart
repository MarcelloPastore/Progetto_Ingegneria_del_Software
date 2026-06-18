import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class CreateTurnoUseCase {
  const CreateTurnoUseCase(this._repository);

  final ITurniRepository _repository;

  Future<Turno> call(String casaId, Map<String, dynamic> payload) =>
      _repository.createTurno(casaId, payload);
}
