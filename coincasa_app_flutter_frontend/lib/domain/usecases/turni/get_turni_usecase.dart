import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class GetTurniUseCase {
  const GetTurniUseCase(this._repository);

  final ITurniRepository _repository;

  Future<List<Turno>> call(String casaId) => _repository.getTurni(casaId);
}
