import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';
import 'package:coincasa_app/domain/usecases/casa/get_casa_by_id_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/update_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/get_inquilini_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/remove_inquilino_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/update_ruolo_inquilino_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/get_invite_link_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/regenerate_invite_link_usecase.dart';

class HubCasaState {
  const HubCasaState({
    required this.casa,
    required this.inquilini,
    this.inviteLink,
  });

  final Casa casa;
  final List<Inquilino> inquilini;
  final String? inviteLink;

  HubCasaState copyWith({
    Casa? casa,
    List<Inquilino>? inquilini,
    String? inviteLink,
  }) {
    return HubCasaState(
      casa: casa ?? this.casa,
      inquilini: inquilini ?? this.inquilini,
      inviteLink: inviteLink ?? this.inviteLink,
    );
  }
}

class HubCasaViewModel extends FamilyAsyncNotifier<HubCasaState, String> {
  late ICasaRepository _repository;
  late GetCasaByIdUseCase _getCasaById;
  late UpdateCasaUseCase _updateCasa;
  late GetInquiliniUseCase _getInquilini;
  late RemoveInquilinoUseCase _removeInquilino;
  late UpdateRuoloInquilinoUseCase _updateRuolo;
  late GetInviteLinkUseCase _getInviteLink;
  late RegenerateInviteLinkUseCase _regenerateInviteLink;

  @override
  Future<HubCasaState> build(String casaId) async {
    _repository = ref.read(casaRepositoryProvider);
    _getCasaById = GetCasaByIdUseCase(_repository);
    _updateCasa = UpdateCasaUseCase(_repository);
    _getInquilini = GetInquiliniUseCase(_repository);
    _removeInquilino = RemoveInquilinoUseCase(_repository);
    _updateRuolo = UpdateRuoloInquilinoUseCase(_repository);
    _getInviteLink = GetInviteLinkUseCase(_repository);
    _regenerateInviteLink = RegenerateInviteLinkUseCase(_repository);

    final results = await Future.wait([
      _getCasaById(casaId),
      _getInquilini(casaId),
    ]);

    return HubCasaState(
      casa: results[0] as Casa,
      inquilini: results[1] as List<Inquilino>,
    );
  }

  Future<void> updateCasa(Map<String, dynamic> payload) async {
    final current = state.requireValue;
    await _updateCasa(current.casa.id, payload);
    ref.invalidateSelf();
  }

  Future<void> removeInquilino(String inquilinoId) async {
    final casaId = state.requireValue.casa.id;
    await _removeInquilino(casaId, inquilinoId);
    final inquilini = await _getInquilini(casaId);
    state = AsyncData(state.requireValue.copyWith(inquilini: inquilini));
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
