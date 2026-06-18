import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/data/repository/problemi_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';
import 'package:coincasa_app/domain/usecases/problemi/get_problemi_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/get_problemi_non_risolti_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/create_problema_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/auto_assegna_problema_usecase.dart';

class ProblemiState {
  const ProblemiState({
    required this.problemi,
    this.mostraTutti = false,
  });

  final List<Problema> problemi;
  final bool mostraTutti;

  ProblemiState copyWith({List<Problema>? problemi, bool? mostraTutti}) {
    return ProblemiState(
      problemi: problemi ?? this.problemi,
      mostraTutti: mostraTutti ?? this.mostraTutti,
    );
  }
}

class ProblemiViewModel extends FamilyAsyncNotifier<ProblemiState, String> {
  late IProblemiRepository _repo;
  late GetProblemiUseCase _getProblemi;
  late GetProblemiNonRisoltiUseCase _getProblemiNonRisolti;
  late CreateProblemaUseCase _createProblema;
  late AutoAssegnaProblemaUseCase _autoAssegna;

  @override
  Future<ProblemiState> build(String casaId) async {
    _repo = ref.read(problemiRepositoryProvider);
    _getProblemi = GetProblemiUseCase(_repo);
    _getProblemiNonRisolti = GetProblemiNonRisoltiUseCase(_repo);
    _createProblema = CreateProblemaUseCase(_repo);
    _autoAssegna = AutoAssegnaProblemaUseCase(_repo);

    final problemi = await _getProblemiNonRisolti(casaId);
    return ProblemiState(
      problemi: problemi..sort(Problema.compareByPriority),
    );
  }

  Future<void> toggleMostraTutti() async {
    final mostraTutti = !state.requireValue.mostraTutti;
    final problemi = mostraTutti
        ? await _getProblemi(arg)
        : await _getProblemiNonRisolti(arg);
    state = AsyncData(ProblemiState(
      problemi: problemi..sort(Problema.compareByPriority),
      mostraTutti: mostraTutti,
    ));
  }

  /// Segnala un nuovo problema e opzionalmente auto-assegna all'utente corrente.
  Future<Problema> segnalaProblema(
    Map<String, dynamic> payload, {
    bool autoAssegna = false,
  }) async {
    final problema = await _createProblema(arg, payload);
    final result =
        autoAssegna ? await _autoAssegna(arg, problema.id) : problema;
    ref.invalidateSelf();
    return result;
  }

  void refresh() => ref.invalidateSelf();
}

final problemiViewModelProvider =
    AsyncNotifierProviderFamily<ProblemiViewModel, ProblemiState, String>(
  ProblemiViewModel.new,
);
