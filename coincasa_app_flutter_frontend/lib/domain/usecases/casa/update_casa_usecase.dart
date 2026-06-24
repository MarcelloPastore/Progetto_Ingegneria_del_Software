import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class UpdateCasaUseCase {
  const UpdateCasaUseCase(this._repository);

  final ICasaRepository _repository;

  Future<void> call(String casaId, Map<String, dynamic> payload) =>
      _repository.updateCasa(casaId, payload);
}
