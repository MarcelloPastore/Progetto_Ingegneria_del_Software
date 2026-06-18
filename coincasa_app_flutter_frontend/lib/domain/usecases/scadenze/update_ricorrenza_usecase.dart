import 'package:coincasa_app/core/models/scadenza.dart';
import 'package:coincasa_app/domain/repositories/i_scadenze_repository.dart';

class UpdateRicorrenzaUseCase {
  const UpdateRicorrenzaUseCase(this._repository);

  final IScadenzeRepository _repository;

  Future<Scadenza> call(
    String casaId,
    String idScadenza,
    Map<String, dynamic> payload,
  ) =>
      _repository.updateRicorrenza(casaId, idScadenza, payload);
}
