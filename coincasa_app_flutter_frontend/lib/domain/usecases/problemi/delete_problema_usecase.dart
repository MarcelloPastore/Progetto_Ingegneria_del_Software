import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class DeleteProblemaUseCase {
  const DeleteProblemaUseCase(this._repository);

  final IProblemiRepository _repository;

  Future<void> call(String casaId, String problemaId) =>
      _repository.deleteProblema(casaId, problemaId);
}
