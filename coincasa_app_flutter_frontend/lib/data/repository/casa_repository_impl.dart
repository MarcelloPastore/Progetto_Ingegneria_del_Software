import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';

class CasaRepositoryImpl implements ICasaRepository {
  const CasaRepositoryImpl();

  @override
  Future<List<Casa>> getCase() => ApiProvider.casa.list();

  @override
  Future<Casa> getCasaById(String casaId) => ApiProvider.casa.getById(casaId);

  @override
  Future<Casa> createCasa(Map<String, dynamic> payload) =>
      ApiProvider.casa.create(payload);

  @override
  Future<void> updateCasa(String casaId, Map<String, dynamic> payload) =>
      ApiProvider.casa.update(casaId, payload);

  @override
  Future<void> deleteCasa(String casaId) => ApiProvider.casa.delete(casaId);

  @override
  Future<Casa> joinCasa(String inviteCodeOrLink) =>
      ApiProvider.casa.joinWithInviteCode(inviteCodeOrLink);

  @override
  Future<String> selectCasa(String casaId) =>
      ApiProvider.casa.selectCasa(casaId);

  @override
  Future<Map<String, dynamic>> getHub(String casaId) =>
      ApiProvider.casa.getHub(casaId);

  @override
  Future<List<Inquilino>> getInquilini(String casaId) =>
      ApiProvider.casa.listInquilini(casaId);

  @override
  Future<Inquilino> getInquilino(String casaId, String inquilinoId) =>
      ApiProvider.casa.getInquilino(casaId, inquilinoId);

  @override
  Future<void> removeInquilino(String casaId, String inquilinoId) =>
      ApiProvider.casa.removeInquilino(casaId, inquilinoId);

  @override
  Future<void> updateRuoloInquilino(
    String casaId,
    String inquilinoId,
    Map<String, dynamic> payload,
  ) =>
      ApiProvider.casa.updateRuolo(casaId, inquilinoId, payload);

  @override
  Future<String> getInviteLink(String casaId) =>
      ApiProvider.casa.getInviteLink(casaId);

  @override
  Future<String> regenerateInviteLink(String casaId) =>
      ApiProvider.casa.regenerateInviteLink(casaId);
}

final casaRepositoryProvider = Provider<ICasaRepository>(
  (_) => const CasaRepositoryImpl(),
);
