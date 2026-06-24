import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/domain/repositories/i_scadenze_repository.dart';

class UpdateScadenzaUseCase {
  const UpdateScadenzaUseCase(this._repository);

  final IScadenzeRepository _repository;

  Future<Scadenza> call(
    String casaId,
    String idScadenza,
    Map<String, dynamic> payload,
  ) =>
      _repository.updateScadenza(casaId, idScadenza, payload);
}
