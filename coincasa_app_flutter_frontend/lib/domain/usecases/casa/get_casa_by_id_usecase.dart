import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class GetCasaByIdUseCase {
  const GetCasaByIdUseCase(this._repository);

  final ICasaRepository _repository;

  Future<Casa> call(String casaId) => _repository.getCasaById(casaId);
}
