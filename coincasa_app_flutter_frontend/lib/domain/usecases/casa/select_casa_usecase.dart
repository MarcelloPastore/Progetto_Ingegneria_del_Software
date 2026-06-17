import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class SelectCasaUseCase {
  const SelectCasaUseCase(this._repository);

  final ICasaRepository _repository;

  Future<String> call(String casaId) => _repository.selectCasa(casaId);
}
