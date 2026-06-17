import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class JoinCasaUseCase {
  const JoinCasaUseCase(this._repository);

  final ICasaRepository _repository;

  Future<Casa> call(String inviteCodeOrLink) =>
      _repository.joinCasa(inviteCodeOrLink);
}
