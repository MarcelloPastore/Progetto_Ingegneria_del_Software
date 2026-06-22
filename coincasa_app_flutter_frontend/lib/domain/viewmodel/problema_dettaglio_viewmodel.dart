import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/data/repository/problemi_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_problemi_repository.dart';
import 'package:coincasa_app/domain/usecases/problemi/get_problema_by_id_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/update_problema_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/delete_problema_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/auto_assegna_problema_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/rinuncia_problema_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/assegna_problema_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/aggiorna_stato_problema_usecase.dart';
import 'package:coincasa_app/domain/usecases/problemi/aggiorna_priorita_problema_usecase.dart';

/// Chiave di famiglia: record con casaId e problemaId.
typedef ProblemaDettaglioKey = ({String casaId, String problemaId});

class ProblemaDettaglioViewModel
    extends FamilyAsyncNotifier<Problema, ProblemaDettaglioKey> {
  late IProblemiRepository _repo;
  late GetProblemaByIdUseCase _getById;
  late UpdateProblemaUseCase _update;
  late DeleteProblemaUseCase _delete;
  late AutoAssegnaProblemaUseCase _autoAssegna;
  late RinunciaProblemaUseCase _rinuncia;
  late AssegnaProblemaUseCase _assegna;
  late AggiornaStatoProblemaUseCase _aggiornaStato;
  late AggiornaPrioritaProblemaUseCase _aggiornaPriorita;

  @override
  Future<Problema> build(ProblemaDettaglioKey key) async {
    _repo = ref.read(problemiRepositoryProvider);
    _getById = GetProblemaByIdUseCase(_repo);
    _update = UpdateProblemaUseCase(_repo);
    _delete = DeleteProblemaUseCase(_repo);
    _autoAssegna = AutoAssegnaProblemaUseCase(_repo);
    _rinuncia = RinunciaProblemaUseCase(_repo);
    _assegna = AssegnaProblemaUseCase(_repo);
    _aggiornaStato = AggiornaStatoProblemaUseCase(_repo);
    _aggiornaPriorita = AggiornaPrioritaProblemaUseCase(_repo);

    return _getById(key.casaId, key.problemaId);
  }

  Future<void> updateProblema(Map<String, dynamic> payload) async {
    final updated = await _update(arg.casaId, arg.problemaId, payload);
    state = AsyncData(updated);
  }

  /// Elimina il problema. Il chiamante deve navigare via dopo la risoluzione.
  Future<void> deleteProblema() => _delete(arg.casaId, arg.problemaId);

  Future<void> autoAssegna() async {
    final updated = await _autoAssegna(arg.casaId, arg.problemaId);
    state = AsyncData(updated);
  }

  Future<void> rinuncia() async {
    final updated = await _rinuncia(arg.casaId, arg.problemaId);
    state = AsyncData(updated);
  }

  /// Assegnazione diretta da admin.
  Future<void> assegna(String assegnatarioId) async {
    final updated = await _assegna(arg.casaId, arg.problemaId, assegnatarioId);
    state = AsyncData(updated);
  }

  /// [stato] deve essere uno dei valori di [StatoProblema].
  Future<void> aggiornaStato(String stato) async {
    final updated = await _aggiornaStato(arg.casaId, arg.problemaId, stato);
    state = AsyncData(updated);
  }

  /// [priorita] deve essere uno dei valori di [PrioritaProblema].
  Future<void> aggiornaPriorita(String priorita) async {
    final updated =
        await _aggiornaPriorita(arg.casaId, arg.problemaId, priorita);
    state = AsyncData(updated);
  }

  void refresh() => ref.invalidateSelf();
}

final problemaDettaglioViewModelProvider = AsyncNotifierProviderFamily<
    ProblemaDettaglioViewModel, Problema, ProblemaDettaglioKey>(
  ProblemaDettaglioViewModel.new,
);
