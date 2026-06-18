import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/data/repository/spese_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';
import 'package:coincasa_app/domain/usecases/spese/create_spesa_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/delete_spesa_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/get_credito_totale_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/get_credito_verso_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/get_debito_totale_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/get_debito_verso_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/get_quote_spesa_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/get_saldo_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/get_spesa_by_id_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/get_spese_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/paga_quota_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/pareggia_conti_usecase.dart';
import 'package:coincasa_app/domain/usecases/spese/update_spesa_usecase.dart';

class SpeseState {
  const SpeseState({
    required this.spese,
    required this.saldo,
    required this.creditoTotale,
    required this.debitoTotale,
  });

  final List<Spesa> spese;
  final double saldo;
  final double creditoTotale;
  final double debitoTotale;
}

class SpeseViewModel extends FamilyAsyncNotifier<SpeseState, String> {
  late ISpeseRepository _repository;
  late GetSpeseUseCase _getSpese;
  late GetSpesaByIdUseCase _getSpesaById;
  late CreateSpesaUseCase _createSpesa;
  late UpdateSpesaUseCase _updateSpesa;
  late DeleteSpesaUseCase _deleteSpesa;
  late GetQuoteSpesaUseCase _getQuoteSpesa;
  late PagaQuotaUseCase _pagaQuota;
  late PareggiaContiUseCase _pareggiaConti;
  late GetSaldoUseCase _getSaldo;
  late GetCreditoTotaleUseCase _getCreditoTotale;
  late GetDebitoTotaleUseCase _getDebitoTotale;
  late GetCreditoVersoUseCase _getCreditoVerso;
  late GetDebitoVersoUseCase _getDebitoVerso;

  @override
  Future<SpeseState> build(String casaId) async {
    _repository = ref.read(speseRepositoryProvider);
    _getSpese = GetSpeseUseCase(_repository);
    _getSpesaById = GetSpesaByIdUseCase(_repository);
    _createSpesa = CreateSpesaUseCase(_repository);
    _updateSpesa = UpdateSpesaUseCase(_repository);
    _deleteSpesa = DeleteSpesaUseCase(_repository);
    _getQuoteSpesa = GetQuoteSpesaUseCase(_repository);
    _pagaQuota = PagaQuotaUseCase(_repository);
    _pareggiaConti = PareggiaContiUseCase(_repository);
    _getSaldo = GetSaldoUseCase(_repository);
    _getCreditoTotale = GetCreditoTotaleUseCase(_repository);
    _getDebitoTotale = GetDebitoTotaleUseCase(_repository);
    _getCreditoVerso = GetCreditoVersoUseCase(_repository);
    _getDebitoVerso = GetDebitoVersoUseCase(_repository);

    final spese = await _getSpese(casaId);
    final saldo = await _getSaldo(casaId);
    final creditoTotale = await _getCreditoTotale(casaId);
    final debitoTotale = await _getDebitoTotale(casaId);

    return SpeseState(
      spese: spese,
      saldo: saldo,
      creditoTotale: creditoTotale,
      debitoTotale: debitoTotale,
    );
  }

  Future<Spesa> getSpesaById(String idSpesa) => _getSpesaById(arg, idSpesa);

  Future<List<Quota>> getQuoteSpesa(String idSpesa) =>
      _getQuoteSpesa(arg, idSpesa);

  Future<double> getCreditoVerso(String idInquilino) =>
      _getCreditoVerso(arg, idInquilino);

  Future<double> getDebitoVerso(String idInquilino) =>
      _getDebitoVerso(arg, idInquilino);

  Future<Spesa> createSpesa(Map<String, dynamic> payload) async {
    final spesa = await _createSpesa(arg, payload);
    ref.invalidateSelf();
    return spesa;
  }

  Future<Spesa> updateSpesa(
    String idSpesa,
    Map<String, dynamic> payload,
  ) async {
    final spesa = await _updateSpesa(arg, idSpesa, payload);
    ref.invalidateSelf();
    return spesa;
  }

  Future<void> deleteSpesa(String idSpesa) async {
    await _deleteSpesa(arg, idSpesa);
    ref.invalidateSelf();
  }

  Future<void> pagaQuota(String idSpesa, String idQuota) async {
    await _pagaQuota(arg, idSpesa, idQuota);
    ref.invalidateSelf();
  }

  Future<void> pareggiaConti(List<String> idUtentiCreditori) async {
    await _pareggiaConti(arg, idUtentiCreditori);
    ref.invalidateSelf();
  }

  void refresh() => ref.invalidateSelf();
}

final speseViewModelProvider =
    AsyncNotifierProviderFamily<SpeseViewModel, SpeseState, String>(
      SpeseViewModel.new,
    );
