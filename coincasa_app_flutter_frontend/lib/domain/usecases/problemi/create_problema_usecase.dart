import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class CreateProblemaUseCase {
  const CreateProblemaUseCase(this._repository);

  final IProblemiRepository _repository;

  Future<Problema> call(String casaId, Map<String, dynamic> payload) =>
      _repository.createProblema(casaId, payload);
}
