import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class AssegnaProblemaUseCase {
  const AssegnaProblemaUseCase(this._repository);

  final IProblemiRepository _repository;

  /// [assegnatarioId] è l'id dell'utente a cui assegnare il problema.
  Future<Problema> call(
    String casaId,
    String problemaId,
    String assegnatarioId,
  ) =>
      _repository.assegnaProblema(
        casaId,
        problemaId,
        {'assegnatarioId': assegnatarioId},
      );
}
