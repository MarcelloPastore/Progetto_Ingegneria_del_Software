import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/data/repository/scadenze_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_scadenze_repository.dart';
import 'package:coincasa_app/domain/usecases/scadenze/get_scadenze_usecase.dart';
import 'package:coincasa_app/domain/usecases/scadenze/create_scadenza_usecase.dart';
import 'package:coincasa_app/domain/usecases/scadenze/update_scadenza_usecase.dart';
import 'package:coincasa_app/domain/usecases/scadenze/update_ricorrenza_usecase.dart';
import 'package:coincasa_app/domain/usecases/scadenze/delete_scadenza_usecase.dart';

class ScadenzeState {
  const ScadenzeState({required this.scadenze});

  final List<Scadenza> scadenze;

  List<Scadenza> get scadute => scadenze
      .where((s) => !s.dataScadenza.isAfter(DateTime.now()))
      .toList();

  List<Scadenza> get prossime =>
      scadenze.where((s) => s.dataScadenza.isAfter(DateTime.now())).toList();
}

class ScadenzeViewModel extends FamilyAsyncNotifier<ScadenzeState, String> {
  late IScadenzeRepository _repo;
  late GetScadenzeUseCase _getScadenze;
  late CreateScadenzaUseCase _createScadenza;
  late UpdateScadenzaUseCase _updateScadenza;
  late UpdateRicorrenzaUseCase _updateRicorrenza;
  late DeleteScadenzaUseCase _deleteScadenza;

  @override
  Future<ScadenzeState> build(String casaId) async {
    _repo = ref.read(scadenzeRepositoryProvider);
    _getScadenze = GetScadenzeUseCase(_repo);
    _createScadenza = CreateScadenzaUseCase(_repo);
    _updateScadenza = UpdateScadenzaUseCase(_repo);
    _updateRicorrenza = UpdateRicorrenzaUseCase(_repo);
    _deleteScadenza = DeleteScadenzaUseCase(_repo);

    final timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!state.hasValue) return;
      try {
        state = AsyncData(ScadenzeState(scadenze: await _getScadenze(casaId)));
      } catch (_) {}
    });
    ref.onDispose(timer.cancel);

    return ScadenzeState(scadenze: await _getScadenze(casaId));
  }

  Future<Scadenza> createScadenza(Map<String, dynamic> payload) async {
    final scadenza = await _createScadenza(arg, payload);
    ref.invalidateSelf();
    return scadenza;
  }

  /// Aggiorna dati base e, se fornito, anche la ricorrenza.
  /// Le due chiamate sono sequenziali perché il backend le espone su
  /// endpoint distinti (PUT /scadenze/:id + PATCH /scadenze/:id/ricorrenza).
  Future<void> updateScadenza(
    String idScadenza, {
    required Map<String, dynamic> datiPayload,
    Map<String, dynamic>? ricorrenzaPayload,
  }) async {
    await _updateScadenza(arg, idScadenza, datiPayload);
    if (ricorrenzaPayload != null) {
      await _updateRicorrenza(arg, idScadenza, ricorrenzaPayload);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteScadenza(String idScadenza) async {
    await _deleteScadenza(arg, idScadenza);
    final updated = state.requireValue.scadenze
        .where((s) => s.id != idScadenza)
        .toList();
    state = AsyncData(ScadenzeState(scadenze: updated));
  }

  void refresh() => ref.invalidateSelf();
}

final scadenzeViewModelProvider =
    AsyncNotifierProviderFamily<ScadenzeViewModel, ScadenzeState, String>(
  ScadenzeViewModel.new,
);
