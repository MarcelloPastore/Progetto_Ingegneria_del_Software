import 'package:coincasa_app/data/models/turno.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class GetTurniOggiUseCase {
  const GetTurniOggiUseCase(this._repository);

  final ITurniRepository _repository;

  Future<List<Turno>> call(String casaId) => _repository.getTurniOggi(casaId);
}
