import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class GetInviteLinkUseCase {
  const GetInviteLinkUseCase(this._repository);

  final ICasaRepository _repository;

  Future<String> call(String casaId) => _repository.getInviteLink(casaId);
}
