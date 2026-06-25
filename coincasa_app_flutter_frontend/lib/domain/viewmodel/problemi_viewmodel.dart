import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/data/repository/problemi_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';
import 'package:coincasa_app/domain/usecases/problemi/get_problemi_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/create_problema_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/auto_assegna_problema_usecase.dart';

class ProblemiState {
  const ProblemiState({required this.tutti, this.mostraTutti = false});

  final List<Problema> tutti;
  final bool mostraTutti;

  bool get hasRisolti =>
      tutti.any((p) => p.stato.toLowerCase().contains('risolt'));

  List<Problema> get problemi {
    final list = mostraTutti
        ? List<Problema>.of(tutti)
        : tutti
              .where((p) => !p.stato.toLowerCase().contains('risolt'))
              .toList();
    return list..sort(Problema.compareByPriority);
  }

  ProblemiState copyWith({List<Problema>? tutti, bool? mostraTutti}) {
    return ProblemiState(
      tutti: tutti ?? this.tutti,
      mostraTutti: mostraTutti ?? this.mostraTutti,
    );
  }
}

class ProblemiViewModel extends FamilyAsyncNotifier<ProblemiState, String> {
  late IProblemiRepository _repo;
  late GetProblemiUseCase _getProblemi;
  late CreateProblemaUseCase _createProblema;
  late AutoAssegnaProblemaUseCase _autoAssegnaUseCase;

  @override
  Future<ProblemiState> build(String casaId) async {
    _repo = ref.read(problemiRepositoryProvider);
    _getProblemi = GetProblemiUseCase(_repo);
    _createProblema = CreateProblemaUseCase(_repo);
    _autoAssegnaUseCase = AutoAssegnaProblemaUseCase(_repo);

    final timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!state.hasValue) return;
      try {
        final current = state.requireValue;
        final tutti = await _getProblemi(casaId);
        state = AsyncData(current.copyWith(tutti: tutti));
      } catch (_) {}
    });
    ref.onDispose(timer.cancel);

    final tutti = await _getProblemi(casaId);
    return ProblemiState(tutti: tutti);
  }

  void toggleMostraTutti() {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(mostraTutti: !current.mostraTutti));
  }

  Future<Problema> segnalaProblema(
    Map<String, dynamic> payload, {
    bool autoAssegna = false,
  }) async {
    final problema = await _createProblema(arg, payload);
    final result =
        autoAssegna ? await _autoAssegnaUseCase(arg, problema.id) : problema;
    ref.invalidateSelf();
    return result;
  }

  Future<Problema> getById(String problemaId) =>
      ApiProvider.problemi.getById(arg, problemaId);

  Future<Problema> autoAssegnaEsistente(String problemaId) async {
    final updated = await ApiProvider.problemi.autoAssegna(arg, problemaId);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> rinuncia(String problemaId) async {
    await ApiProvider.problemi.rinuncia(arg, problemaId);
    ref.invalidateSelf();
  }

  Future<Problema> aggiornaStato(
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    final updated =
        await ApiProvider.problemi.aggiornaStato(arg, problemaId, payload);
    ref.invalidateSelf();
    return updated;
  }

  Future<Problema> aggiornaPriorita(
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    final updated =
        await ApiProvider.problemi.aggiornaPriorita(arg, problemaId, payload);
    ref.invalidateSelf();
    return updated;
  }

  Future<Problema> updateProblema(
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    final updated =
        await ApiProvider.problemi.update(arg, problemaId, payload);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> deleteProblema(String problemaId) async {
    await ApiProvider.problemi.delete(arg, problemaId);
    ref.invalidateSelf();
  }

  void refresh() => ref.invalidateSelf();
}

final problemiViewModelProvider =
    AsyncNotifierProviderFamily<ProblemiViewModel, ProblemiState, String>(
      ProblemiViewModel.new,
    );
