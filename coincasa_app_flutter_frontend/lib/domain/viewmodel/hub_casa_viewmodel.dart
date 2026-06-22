import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/api/spese_repository_provider.dart';
import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';
import 'package:coincasa_app/domain/usecases/casa/get_hub_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/update_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/delete_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/get_inquilini_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/remove_inquilino_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/lascia_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/update_ruolo_inquilino_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/get_invite_link_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/regenerate_invite_link_usecase.dart';
import 'package:coincasa_app/domain/value_objects/ruolo_casa.dart';

class HubCasaState {
  const HubCasaState({
    required this.casa,
    required this.inquilini,
    required this.ruolo,
    required this.isCurrentUserOwner,
    required this.spese,
    required this.speseCount,
    required this.scadenzeCount,
    required this.problemiCount,
    required this.turniCount,
    this.inviteLink,
  });

  final Casa casa;
  final List<Inquilino> inquilini;
  final String ruolo;
  final bool isCurrentUserOwner;
  final List<Spesa> spese;
  final String? inviteLink;
  final int speseCount;
  final int scadenzeCount;
  final int problemiCount;
  final int turniCount;

  bool get isAdmin => RuoloCasa.isAdmin(ruolo);

  int get speseNonSaldateCount {
    return spese.where((s) {
      if (s.partecipanti.isEmpty) return false;
      return s.partecipanti.any((q) {
        final raw = q['pagata'] ?? q['pagato'] ?? q['isPaid'];
        final pagata = raw == true || raw?.toString().toLowerCase() == 'true';
        return !pagata;
      });
    }).length;
  }

  List<Spesa> spesePendentiPer(String userId) {
    return spese.where((spesa) {
      if (spesa.partecipanti.isEmpty) return false;
      return spesa.partecipanti.any((q) {
        final uid = (q['utenteId'] ?? q['idUtente'] ?? q['inquilinoId'] ??
                    (q['utente'] as Map?)?['id'])
                ?.toString()
                .trim() ??
            '';
        final raw = q['pagata'] ?? q['pagato'] ?? q['isPaid'];
        final pagata = raw == true || raw?.toString().toLowerCase() == 'true';
        return uid == userId && !pagata;
      });
    }).toList();
  }

  HubCasaState copyWith({
    Casa? casa,
    List<Inquilino>? inquilini,
    String? ruolo,
    bool? isCurrentUserOwner,
    List<Spesa>? spese,
    String? inviteLink,
    int? speseCount,
    int? scadenzeCount,
    int? problemiCount,
    int? turniCount,
  }) {
    return HubCasaState(
      casa: casa ?? this.casa,
      inquilini: inquilini ?? this.inquilini,
      ruolo: ruolo ?? this.ruolo,
      isCurrentUserOwner: isCurrentUserOwner ?? this.isCurrentUserOwner,
      spese: spese ?? this.spese,
      inviteLink: inviteLink ?? this.inviteLink,
      speseCount: speseCount ?? this.speseCount,
      scadenzeCount: scadenzeCount ?? this.scadenzeCount,
      problemiCount: problemiCount ?? this.problemiCount,
      turniCount: turniCount ?? this.turniCount,
    );
  }
}

class HubCasaViewModel extends FamilyAsyncNotifier<HubCasaState, String> {
  late ICasaRepository _casaRepo;
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
    _getHub = GetHubUseCase(_casaRepo, ref.read(speseRepositoryProvider));
    _updateCasa = UpdateCasaUseCase(_casaRepo);
    _deleteCasa = DeleteCasaUseCase(_casaRepo);
    _getInquilini = GetInquiliniUseCase(_casaRepo);
    _removeInquilino = RemoveInquilinoUseCase(_casaRepo);
    _lasciaCasa = LasciaCasaUseCase(_casaRepo);
    _updateRuolo = UpdateRuoloInquilinoUseCase(_casaRepo);
    _getInviteLink = GetInviteLinkUseCase(_casaRepo);
    _regenerateInviteLink = RegenerateInviteLinkUseCase(_casaRepo);

    final result = await _getHub(casaId);
    final current = result.currentInquilino;
    if (current != null) {
      ApiProvider.client.setCurrentUserIdentity(
        id: current.id,
        email: current.email,
        name: current.nome,
        surname: current.cognome,
        displayName: current.nomeCompleto,
        username: current.username,
      );
    }

    return HubCasaState(
      casa: result.hub.casa,
      inquilini: result.hub.inquilini,
      ruolo: result.hub.ruolo,
      isCurrentUserOwner: result.hub.isCurrentUserOwner,
      spese: result.spese,
      speseCount: result.hub.speseCount,
      scadenzeCount: result.hub.scadenzeCount,
      problemiCount: result.hub.problemiCount,
      turniCount: result.hub.turniCount,
    );
  }

  Future<void> updateCasa(Map<String, dynamic> payload) async {
    final casaId = state.requireValue.casa.id;
    await _updateCasa(casaId, payload);
    ref.invalidateSelf();
  }

  Future<void> deleteCasa() async {
    final casaId = state.requireValue.casa.id;
    await _deleteCasa(casaId);
  }

  Future<void> removeInquilino(String inquilinoId) async {
    final casaId = state.requireValue.casa.id;
    await _removeInquilino(casaId, inquilinoId);
    final inquilini = await _getInquilini(casaId);
    state = AsyncData(state.requireValue.copyWith(inquilini: inquilini));
  }

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
