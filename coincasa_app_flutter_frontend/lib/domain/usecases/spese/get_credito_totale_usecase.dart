import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class GetCreditoTotaleUseCase {
  const GetCreditoTotaleUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<double> call(String casaId) => _repository.getCreditoTotale(casaId);
}
