import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class GetQuoteSpesaUseCase {
  const GetQuoteSpesaUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<List<Quota>> call(String casaId, String idSpesa) =>
      _repository.getQuoteSpesa(casaId, idSpesa);
}
