import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class PareggiaContiUseCase {
  const PareggiaContiUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<void> call(String casaId, List<String> idUtentiCreditori) =>
      _repository.pareggiaConti(casaId, idUtentiCreditori);
}
