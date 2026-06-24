import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class DeleteCasaUseCase {
  const DeleteCasaUseCase(this._repository);

  final ICasaRepository _repository;

  Future<void> call(String casaId) => _repository.deleteCasa(casaId);
}
