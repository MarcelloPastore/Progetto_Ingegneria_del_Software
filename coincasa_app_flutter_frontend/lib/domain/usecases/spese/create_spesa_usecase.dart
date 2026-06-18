import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class CreateSpesaUseCase {
  const CreateSpesaUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<Spesa> call(String casaId, Map<String, dynamic> payload) =>
      _repository.createSpesa(casaId, payload);
}
