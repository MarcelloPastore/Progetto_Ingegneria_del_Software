import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class RemoveInquilinoUseCase {
  const RemoveInquilinoUseCase(this._repository);

  final ICasaRepository _repository;

  Future<void> call(String casaId, String inquilinoId) =>
      _repository.removeInquilino(casaId, inquilinoId);
}
