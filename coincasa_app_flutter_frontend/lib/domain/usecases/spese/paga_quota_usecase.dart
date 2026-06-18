import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class PagaQuotaUseCase {
  const PagaQuotaUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<void> call(String casaId, String idSpesa, String idQuota) =>
      _repository.pagaQuota(casaId, idSpesa, idQuota);
}
