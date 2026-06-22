import 'package:coincasa_app/data/models/salute_casa_item.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';

class GetSaluteCasaUseCase {
  const GetSaluteCasaUseCase(this._repository);

  final ITurniRepository _repository;

  Future<List<SaluteCasaItem>> call(String casaId) =>
      _repository.getSaluteCasa(casaId);
}
