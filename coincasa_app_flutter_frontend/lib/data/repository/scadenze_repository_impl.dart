import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/scadenza.dart';
import 'package:coincasa_app/domain/repositories/i_scadenze_repository.dart';

class ScadenzeRepositoryImpl implements IScadenzeRepository {
  const ScadenzeRepositoryImpl();

  @override
  Future<List<Scadenza>> getScadenze(String casaId) =>
      ApiProvider.scadenze.list(casaId);

  @override
  Future<Scadenza> getScadenzaById(String casaId, String idScadenza) =>
      ApiProvider.scadenze.getById(casaId, idScadenza);

  @override
  Future<Scadenza> createScadenza(
    String casaId,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.scadenze.create(casaId, payload);

  @override
  Future<Scadenza> updateScadenza(
    String casaId,
    String idScadenza,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.scadenze.update(casaId, idScadenza, payload);

  @override
  Future<Scadenza> updateRicorrenza(
    String casaId,
    String idScadenza,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.scadenze.updateRicorrenza(casaId, idScadenza, payload);

  @override
  Future<void> deleteScadenza(String casaId, String idScadenza) =>
      ApiProvider.scadenze.delete(casaId, idScadenza);
}

final scadenzeRepositoryProvider = Provider<IScadenzeRepository>(
  (_) => const ScadenzeRepositoryImpl(),
);
