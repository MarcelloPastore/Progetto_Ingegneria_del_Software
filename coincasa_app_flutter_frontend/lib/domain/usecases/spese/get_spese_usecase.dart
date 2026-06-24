import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class GetSpeseUseCase {
  const GetSpeseUseCase(this._repository);

  final ISpeseRepository _repository;

  Future<List<Spesa>> call(
    String casaId, {
    Map<String, String>? queryParameters,
  }) => _repository.getSpese(casaId, queryParameters: queryParameters);
}
