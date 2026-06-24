import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class UpdateSpesaUseCase {
  const UpdateSpesaUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<Spesa> call(
    String casaId,
    String idSpesa,
    Map<String, dynamic> payload,
  ) => _repository.updateSpesa(casaId, idSpesa, payload);
}
