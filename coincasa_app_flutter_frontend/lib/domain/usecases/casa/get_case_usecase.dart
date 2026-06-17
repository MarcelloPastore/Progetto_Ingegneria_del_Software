import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class GetCaseUseCase {
  const GetCaseUseCase(this._repository);

  final ICasaRepository _repository;

  Future<List<Casa>> call() => _repository.getCase();
}
