import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class UpdateProblemaUseCase {
  const UpdateProblemaUseCase(this._repository);

  final IProblemiRepository _repository;

  Future<Problema> call(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) =>
      _repository.updateProblema(casaId, problemaId, payload);
}
