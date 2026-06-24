import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class GetDebitoVersoUseCase {
  const GetDebitoVersoUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<double> call(String casaId, String idInquilino) =>
      _repository.getDebitoVerso(casaId, idInquilino);
}
