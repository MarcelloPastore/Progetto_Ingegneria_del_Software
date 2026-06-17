import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class GetInquiliniUseCase {
  const GetInquiliniUseCase(this._repository);

  final ICasaRepository _repository;

  Future<List<Inquilino>> call(String casaId) =>
      _repository.getInquilini(casaId);
}
