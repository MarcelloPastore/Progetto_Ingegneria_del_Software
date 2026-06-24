import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class GetInquilinoUseCase {
  const GetInquilinoUseCase(this._repository);

  final ICasaRepository _repository;

  Future<Inquilino> call(String casaId, String inquilinoId) =>
      _repository.getInquilino(casaId, inquilinoId);
}
