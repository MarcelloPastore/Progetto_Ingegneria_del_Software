import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class AggiornaStatoProblemaUseCase {
  const AggiornaStatoProblemaUseCase(this._repository);

  final IProblemiRepository _repository;

  /// [stato] deve essere uno dei valori di [StatoProblema].
  Future<Problema> call(String casaId, String problemaId, String stato) =>
      _repository.aggiornaStatoProblema(
        casaId,
        problemaId,
        {'stato': stato},
      );
}
