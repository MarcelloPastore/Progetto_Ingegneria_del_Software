import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class GetDebitoTotaleUseCase {
  const GetDebitoTotaleUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<double> call(String casaId) => _repository.getDebitoTotale(casaId);
}
