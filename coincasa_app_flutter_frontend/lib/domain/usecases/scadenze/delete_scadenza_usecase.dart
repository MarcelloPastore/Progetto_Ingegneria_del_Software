import 'package:coincasa_app/domain/repositories/i_scadenze_repository.dart';

class DeleteScadenzaUseCase {
  const DeleteScadenzaUseCase(this._repository);

  final IScadenzeRepository _repository;

  Future<void> call(String casaId, String idScadenza) =>
      _repository.deleteScadenza(casaId, idScadenza);
}
