import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class AutoAssegnaProblemaUseCase {
  const AutoAssegnaProblemaUseCase(this._repository);

  final IProblemiRepository _repository;

  Future<Problema> call(String casaId, String problemaId) =>
      _repository.autoAssegnaProblema(casaId, problemaId);
}
