import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class UpdateRuoloInquilinoUseCase {
  const UpdateRuoloInquilinoUseCase(this._repository);

  final ICasaRepository _repository;

  Future<void> call(
    String casaId,
    String inquilinoId,
    Map<String, dynamic> payload,
  ) =>
      _repository.updateRuoloInquilino(casaId, inquilinoId, payload);
}
