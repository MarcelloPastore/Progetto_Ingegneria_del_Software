import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class DeleteSpesaUseCase {
  const DeleteSpesaUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<void> call(String casaId, String idSpesa) =>
      _repository.deleteSpesa(casaId, idSpesa);
}
