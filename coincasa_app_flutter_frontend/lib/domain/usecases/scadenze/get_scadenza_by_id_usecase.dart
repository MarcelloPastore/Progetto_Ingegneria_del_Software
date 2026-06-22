import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/domain/repositories/i_scadenze_repository.dart';

class GetScadenzaByIdUseCase {
  const GetScadenzaByIdUseCase(this._repository);

  final IScadenzeRepository _repository;

  Future<Scadenza> call(String casaId, String idScadenza) =>
      _repository.getScadenzaById(casaId, idScadenza);
}
