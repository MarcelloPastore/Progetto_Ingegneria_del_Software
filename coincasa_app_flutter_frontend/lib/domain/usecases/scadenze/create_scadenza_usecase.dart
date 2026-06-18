import 'package:coincasa_app/core/models/scadenza.dart';
import 'package:coincasa_app/domain/repositories/i_scadenze_repository.dart';

class CreateScadenzaUseCase {
  const CreateScadenzaUseCase(this._repository);

  final IScadenzeRepository _repository;

  Future<Scadenza> call(String casaId, Map<String, dynamic> payload) =>
      _repository.createScadenza(casaId, payload);
}
