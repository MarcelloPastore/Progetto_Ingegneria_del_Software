import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class GetCreditoVersoUseCase {
  const GetCreditoVersoUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<double> call(String casaId, String idInquilino) =>
      _repository.getCreditoVerso(casaId, idInquilino);
}
