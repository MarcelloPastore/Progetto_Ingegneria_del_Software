import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';
import 'package:coincasa_app/data/repository/dashboard_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';
import 'package:coincasa_app/domain/repositories/i_dashboard_repository.dart';
import 'package:coincasa_app/domain/usecases/casa/get_casa_by_id_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/update_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/delete_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/get_inquilini_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/remove_inquilino_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/lascia_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/update_ruolo_inquilino_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/get_invite_link_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/regenerate_invite_link_usecase.dart';

class HubCasaState {
  const HubCasaState({
    required this.casa,
    required this.inquilini,
    required this.spese,
    this.inviteLink,
  });

  final Casa casa;
  final List<Inquilino> inquilini;
  final List<Spesa> spese;
  final String? inviteLink;

  HubCasaState copyWith({
    Casa? casa,
    List<Inquilino>? inquilini,
    List<Spesa>? spese,
    String? inviteLink,
  }) {
    return HubCasaState(
      casa: casa ?? this.casa,
      inquilini: inquilini ?? this.inquilini,
      spese: spese ?? this.spese,
      inviteLink: inviteLink ?? this.inviteLink,
    );
  }
}

class HubCasaViewModel extends FamilyAsyncNotifier<HubCasaState, String> {
  late ICasaRepository _casaRepo;
  late IDashboardRepository _dashboardRepo;
  late GetCasaByIdUseCase _getCasaById;
  late UpdateCasaUseCase _updateCasa;
  late DeleteCasaUseCase _deleteCasa;
  late GetInquiliniUseCase _getInquilini;
  late RemoveInquilinoUseCase _removeInquilino;
  late LasciaCasaUseCase _lasciaCasa;
  late UpdateRuoloInquilinoUseCase _updateRuolo;
  late GetInviteLinkUseCase _getInviteLink;
  late RegenerateInviteLinkUseCase _regenerateInviteLink;

  @override
  Future<HubCasaState> build(String casaId) async {
    _casaRepo = ref.read(casaRepositoryProvider);
    _dashboardRepo = ref.read(dashboardRepositoryProvider);
    _getCasaById = GetCasaByIdUseCase(_casaRepo);
    _updateCasa = UpdateCasaUseCase(_casaRepo);
    _deleteCasa = DeleteCasaUseCase(_casaRepo);
    _getInquilini = GetInquiliniUseCase(_casaRepo);
    _removeInquilino = RemoveInquilinoUseCase(_casaRepo);
    _lasciaCasa = LasciaCasaUseCase(_casaRepo);
    _updateRuolo = UpdateRuoloInquilinoUseCase(_casaRepo);
    _getInviteLink = GetInviteLinkUseCase(_casaRepo);
    _regenerateInviteLink = RegenerateInviteLinkUseCase(_casaRepo);

    final results = await Future.wait([
      _getCasaById(casaId),
      _getInquilini(casaId),
      _dashboardRepo.getSpese(casaId),
    ]);

    return HubCasaState(
      casa: results[0] as Casa,
      inquilini: results[1] as List<Inquilino>,
      spese: results[2] as List<Spesa>,
    );
  }

  Future<void> updateCasa(Map<String, dynamic> payload) async {
    final casaId = state.requireValue.casa.id;
    await _updateCasa(casaId, payload);
    ref.invalidateSelf();
  }

  /// Elimina la casa. Dopo l'eliminazione il chiamante deve navigare via.
  Future<void> deleteCasa() async {
    final casaId = state.requireValue.casa.id;
    await _deleteCasa(casaId);
  }

  /// Rimuove un coinquilino dalla casa e aggiorna la lista localmente.
  Future<void> removeInquilino(String inquilinoId) async {
    final casaId = state.requireValue.casa.id;
    await _removeInquilino(casaId, inquilinoId);
    final inquilini = await _getInquilini(casaId);
    state = AsyncData(state.requireValue.copyWith(inquilini: inquilini));
  }

  /// Rimuove l'utente corrente dalla casa (lascia casa).
  Future<void> lasciaCasa(String currentUserId) async {
    final casaId = state.requireValue.casa.id;
    await _lasciaCasa(casaId, currentUserId);
  }

  Future<void> updateRuoloInquilino(
    String inquilinoId,
    Map<String, dynamic> payload,
  ) async {
    final casaId = state.requireValue.casa.id;
    await _updateRuolo(casaId, inquilinoId, payload);
    final inquilini = await _getInquilini(casaId);
    state = AsyncData(state.requireValue.copyWith(inquilini: inquilini));
  }

  Future<String> loadInviteLink() async {
    final casaId = state.requireValue.casa.id;
    final link = await _getInviteLink(casaId);
    state = AsyncData(state.requireValue.copyWith(inviteLink: link));
    return link;
  }

  Future<String> regenerateInviteLink() async {
    final casaId = state.requireValue.casa.id;
    final link = await _regenerateInviteLink(casaId);
    state = AsyncData(state.requireValue.copyWith(inviteLink: link));
    return link;
  }

  void refresh() => ref.invalidateSelf();
}

final hubCasaViewModelProvider =
    AsyncNotifierProviderFamily<HubCasaViewModel, HubCasaState, String>(
  HubCasaViewModel.new,
);
