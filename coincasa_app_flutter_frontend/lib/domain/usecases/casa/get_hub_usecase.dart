import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/hub_casa_data.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';

class GetHubUseCase {
  const GetHubUseCase(this._casaRepository, this._speseRepository);

  final ICasaRepository _casaRepository;
  final ISpeseRepository _speseRepository;

  Future<({HubCasaData hub, List<Spesa> spese, Inquilino? currentInquilino})>
  call(String casaId) async {
    final results = await Future.wait([
      _casaRepository.getHub(casaId),
      _speseRepository.getSpese(casaId),
    ]);

    final hub = results[0] as HubCasaData;
    final spese = results[1] as List<Spesa>;

    return (
      hub: hub,
      spese: spese,
      currentInquilino: _resolveCurrentInquilino(hub.inquilini),
    );
  }

  Inquilino? _resolveCurrentInquilino(List<Inquilino> inquilini) {
    final currentId = ApiProvider.client.currentUserId?.trim();
    if (currentId != null && currentId.isNotEmpty) {
      for (final c in inquilini) {
        if (c.id.trim() == currentId) return c;
      }
    }
    final currentEmail =
        ApiProvider.client.currentUserEmail?.trim().toLowerCase();
    if (currentEmail != null && currentEmail.isNotEmpty) {
      for (final c in inquilini) {
        if (c.email.trim().toLowerCase() == currentEmail) return c;
      }
    }
    return null;
  }
}
