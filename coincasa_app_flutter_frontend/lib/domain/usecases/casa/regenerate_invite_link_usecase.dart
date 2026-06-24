import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class RegenerateInviteLinkUseCase {
  const RegenerateInviteLinkUseCase(this._repository);

  final ICasaRepository _repository;

  Future<String> call(String casaId) =>
      _repository.regenerateInviteLink(casaId);
}
