import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/domain/repositories/i_scadenze_repository.dart';

class GetScadenzeUseCase {
  const GetScadenzeUseCase(this._repository);

  final IScadenzeRepository _repository;

  Future<List<Scadenza>> call(String casaId) =>
      _repository.getScadenze(casaId);
}
