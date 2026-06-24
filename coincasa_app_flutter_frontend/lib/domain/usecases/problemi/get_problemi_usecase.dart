import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class GetProblemiUseCase {
  const GetProblemiUseCase(this._repository);

  final IProblemiRepository _repository;

  Future<List<Problema>> call(String casaId) =>
      _repository.getProblemi(casaId);
}
