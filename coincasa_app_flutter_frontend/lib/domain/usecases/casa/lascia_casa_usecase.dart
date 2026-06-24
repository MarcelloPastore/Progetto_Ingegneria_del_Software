import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class LasciaCasaUseCase {
  const LasciaCasaUseCase(this._repository);

  final ICasaRepository _repository;

  Future<void> call(String casaId, String currentUserId) =>
      _repository.lasciaCasa(casaId, currentUserId);
}
