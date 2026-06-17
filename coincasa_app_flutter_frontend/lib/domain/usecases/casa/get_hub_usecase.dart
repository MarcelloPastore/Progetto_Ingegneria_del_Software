import 'package:coincasa_app/domain/entities/hub_casa_aggregato.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class GetHubUseCase {
  const GetHubUseCase(this._repository);

  final ICasaRepository _repository;

  Future<HubCasaAggregato> call(String casaId) => _repository.getHub(casaId);
}
