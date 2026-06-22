import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class RinunciaProblemaUseCase {
  const RinunciaProblemaUseCase(this._repository);

  final IProblemiRepository _repository;

  Future<Problema> call(String casaId, String problemaId) =>
      _repository.rinunciaProblema(casaId, problemaId);
}
