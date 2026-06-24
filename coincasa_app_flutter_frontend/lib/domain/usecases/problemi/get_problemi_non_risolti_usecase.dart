import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class GetProblemiNonRisoltiUseCase {
  const GetProblemiNonRisoltiUseCase(this._repository);

  final IProblemiRepository _repository;

  Future<List<Problema>> call(String casaId) =>
      _repository.getProblemiNonRisolti(casaId);
}
