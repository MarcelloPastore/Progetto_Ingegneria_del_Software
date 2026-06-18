import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class AggiornaPrioritaProblemaUseCase {
  const AggiornaPrioritaProblemaUseCase(this._repository);

  final IProblemiRepository _repository;

  /// [priorita] deve essere uno dei valori di [PrioritaProblema].
  Future<Problema> call(String casaId, String problemaId, String priorita) =>
      _repository.aggiornaPrioritaProblema(
        casaId,
        problemaId,
        {'priorita': priorita},
      );
}
