import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class GetSpesaByIdUseCase {
  const GetSpesaByIdUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<Spesa> call(String casaId, String idSpesa) =>
      _repository.getSpesaById(casaId, idSpesa);
}
