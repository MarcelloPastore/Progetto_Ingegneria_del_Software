import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class CreateCasaUseCase {
  const CreateCasaUseCase(this._repository);

  final ICasaRepository _repository;

  Future<Casa> call(Map<String, dynamic> payload) =>
      _repository.createCasa(payload);
}
