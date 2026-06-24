import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';

class ProblemiRepositoryImpl implements IProblemiRepository {
  const ProblemiRepositoryImpl();

  @override
  Future<List<Problema>> getProblemi(String casaId) =>
      ApiProvider.problemi.list(casaId);

  @override
  Future<List<Problema>> getProblemiNonRisolti(String casaId) =>
      ApiProvider.problemi.listNonRisolti(casaId);

  @override
  Future<Problema> getProblemaById(String casaId, String problemaId) =>
      ApiProvider.problemi.getById(casaId, problemaId);

  @override
  Future<Problema> createProblema(
    String casaId,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.problemi.create(casaId, payload);

  @override
  Future<Problema> updateProblema(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.problemi.update(casaId, problemaId, payload);

  @override
  Future<void> deleteProblema(String casaId, String problemaId) =>
      ApiProvider.problemi.delete(casaId, problemaId);

  @override
  Future<Problema> autoAssegnaProblema(String casaId, String problemaId) =>
      ApiProvider.problemi.autoAssegna(casaId, problemaId);

  @override
  Future<Problema> rinunciaProblema(String casaId, String problemaId) =>
      ApiProvider.problemi.rinuncia(casaId, problemaId);

  @override
  Future<Problema> assegnaProblema(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.problemi.assegna(casaId, problemaId, payload);

  @override
  Future<Problema> aggiornaStatoProblema(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.problemi.aggiornaStato(casaId, problemaId, payload);

  @override
  Future<Problema> aggiornaPrioritaProblema(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.problemi.aggiornaPriorita(casaId, problemaId, payload);
}

final problemiRepositoryProvider = Provider<IProblemiRepository>(
  (_) => const ProblemiRepositoryImpl(),
);
