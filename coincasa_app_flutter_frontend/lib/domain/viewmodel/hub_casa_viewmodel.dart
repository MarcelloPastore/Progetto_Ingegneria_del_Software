import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';
import 'package:coincasa_app/data/repository/dashboard_repository_impl.dart';
import 'package:coincasa_app/domain/entities/hub_casa_aggregato.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';
import 'package:coincasa_app/domain/repositories/i_dashboard_repository.dart';
import 'package:coincasa_app/domain/usecases/casa/get_hub_usecase.dart';
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
    required this.hub,
    required this.spese,
    this.inviteLink,
  });

  final HubCasaAggregato hub;
  final List<Spesa> spese;
  final String? inviteLink;

  Casa get casa => hub.casa;
  List<Inquilino> get inquilini => hub.inquilini;
  String get ruolo => hub.ruolo;
  bool get isAdmin => hub.isAdmin;
  bool get isCurrentUserOwner => hub.isCurrentUserOwner;
  int get speseCount => hub.speseCount;
  int get scadenzeCount => hub.scadenzeCount;
  int get problemiCount => hub.problemiCount;
  int get turniCount => hub.turniCount;

  HubCasaState copyWith({
    HubCasaAggregato? hub,
    List<Spesa>? spese,
    String? inviteLink,
  }) {
    return HubCasaState(
      hub: hub ?? this.hub,
      spese: spese ?? this.spese,
      inviteLink: inviteLink ?? this.inviteLink,
    );
  }
}

class HubCasaViewModel extends FamilyAsyncNotifier<HubCasaState, String> {
  late ICasaRepository _casaRepo;
  late IDashboardRepository _dashboardRepo;
  late GetHubUseCase _getHub;
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
    _getHub = GetHubUseCase(_casaRepo);
    _updateCasa = UpdateCasaUseCase(_casaRepo);
    _deleteCasa = DeleteCasaUseCase(_casaRepo);
    _getInquilini = GetInquiliniUseCase(_casaRepo);
    _removeInquilino = RemoveInquilinoUseCase(_casaRepo);
    _lasciaCasa = LasciaCasaUseCase(_casaRepo);
    _updateRuolo = UpdateRuoloInquilinoUseCase(_casaRepo);
    _getInviteLink = GetInviteLinkUseCase(_casaRepo);
    _regenerateInviteLink = RegenerateInviteLinkUseCase(_casaRepo);

    // Due chiamate in parallelo: getHub (include casa + inquilini + contatori)
    // e getSpese (necessaria per la logica di eliminazione/uscita dalla casa).
    final results = await Future.wait([
      _getHub(casaId),
      _dashboardRepo.getSpese(casaId),
    ]);

    return HubCasaState(
      hub: results[0] as HubCasaAggregato,
      spese: results[1] as List<Spesa>,
    );
  }

  Future<void> updateCasa(Map<String, dynamic> payload) async {
    final casaId = state.requireValue.casa.id;
    await _updateCasa(casaId, payload);
    ref.invalidateSelf();
  }

  /// Elimina la casa. Il chiamante deve navigare via dopo la risoluzione.
  Future<void> deleteCasa() async {
    final casaId = state.requireValue.casa.id;
    await _deleteCasa(casaId);
  }

  /// Rimuove un coinquilino e aggiorna la lista localmente.
  Future<void> removeInquilino(String inquilinoId) async {
    final casaId = state.requireValue.casa.id;
    await _removeInquilino(casaId, inquilinoId);
    final inquilini = await _getInquilini(casaId);
    final updatedHub = HubCasaAggregato(
      casa: state.requireValue.casa,
      inquilini: inquilini,
      ruolo: state.requireValue.ruolo,
      isCurrentUserOwner: state.requireValue.isCurrentUserOwner,
      speseCount: state.requireValue.speseCount,
      scadenzeCount: state.requireValue.scadenzeCount,
      problemiCount: state.requireValue.problemiCount,
      turniCount: state.requireValue.turniCount,
    );
    state = AsyncData(state.requireValue.copyWith(hub: updatedHub));
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
    final updatedHub = HubCasaAggregato(
      casa: state.requireValue.casa,
      inquilini: inquilini,
      ruolo: state.requireValue.ruolo,
      isCurrentUserOwner: state.requireValue.isCurrentUserOwner,
      speseCount: state.requireValue.speseCount,
      scadenzeCount: state.requireValue.scadenzeCount,
      problemiCount: state.requireValue.problemiCount,
      turniCount: state.requireValue.turniCount,
    );
    state = AsyncData(state.requireValue.copyWith(hub: updatedHub));
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
