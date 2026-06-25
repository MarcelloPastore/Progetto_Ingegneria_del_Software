import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/auth_user.dart';
import 'package:coincasa_app/core/api/spese_repository_provider.dart';
import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/quota.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';
import 'package:coincasa_app/domain/repositories/i_spese_repository.dart';
import 'package:coincasa_app/domain/usecases/casa/get_inquilini_usecase.dart';
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
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';

class SpeseState {
  const SpeseState({
    required this.spese,
    required this.saldo,
    required this.creditoTotale,
    required this.debitoTotale,
    required this.inquilini,
  });

  final List<Spesa> spese;
  final double saldo;
  final double creditoTotale;
  final double debitoTotale;
  final List<Inquilino> inquilini;
}

enum SpesaStatus { pagata, incompleta, nonPagata }

class SpeseListProjection {
  const SpeseListProjection({
    required this.filtered,
    required this.groupedByMonth,
    required this.sortedMonths,
  });

  factory SpeseListProjection.from(
    List<Spesa> spese, {
    required SpesaStatus? filter,
    required AuthUser? currentUser,
  }) {
    final filtered = filter == null
        ? List<Spesa>.of(spese)
        : spese
              .where((spesa) => spesaStatusFor(spesa, currentUser) == filter)
              .toList();
    final grouped = <DateTime, List<Spesa>>{};
    for (final spesa in filtered) {
      final month = DateTime(spesa.data.year, spesa.data.month);
      grouped.putIfAbsent(month, () => []).add(spesa);
    }
    for (final items in grouped.values) {
      items.sort((a, b) => b.data.compareTo(a.data));
    }
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return SpeseListProjection(
      filtered: List.unmodifiable(filtered),
      groupedByMonth: Map.unmodifiable(grouped),
      sortedMonths: List.unmodifiable(months),
    );
  }

  final List<Spesa> filtered;
  final Map<DateTime, List<Spesa>> groupedByMonth;
  final List<DateTime> sortedMonths;
}

SpesaStatus spesaStatusFor(Spesa spesa, AuthUser? currentUser) {
  final partecipanti = spesa.partecipanti
      .where((item) => item['escluso'] != true)
      .toList();
  if (partecipanti.isEmpty) return SpesaStatus.nonPagata;

  bool isPaid(Map<String, dynamic> item) =>
      item['pagato'] == true ||
      item['pagata'] == true ||
      item['saldato'] == true;
  if (partecipanti.every(isPaid)) return SpesaStatus.pagata;

  for (final item in partecipanti) {
    if (_isCurrentUserPartecipante(item, currentUser)) {
      return isPaid(item) ? SpesaStatus.incompleta : SpesaStatus.nonPagata;
    }
  }
  return SpesaStatus.incompleta;
}

bool spesaHasAnticipatore(Spesa spesa) {
  final raw = spesa.raw;
  final anticipataDa = raw['anticipataDa'];
  if (anticipataDa != null && anticipataDa.toString().trim().isNotEmpty) {
    return true;
  }
  final pagatore = raw['pagatore'];
  if (pagatore is Map && pagatore.isNotEmpty) return true;
  if (pagatore is String && pagatore.trim().isNotEmpty) return true;
  final nome = raw['pagatoreNome'] ?? raw['pagatoDa'];
  return nome != null && nome.toString().trim().isNotEmpty;
}

String quotaUserId(Quota quota) {
  if (quota.utenteId.isNotEmpty) return quota.utenteId;
  final raw = quota.raw;
  final utente = raw['utente'];
  return (raw['inquilinoId'] ??
              raw['idInquilino'] ??
              raw['utenteId'] ??
              raw['idUtente'] ??
              raw['userId'] ??
              (utente is Map ? utente['id'] : null))
          ?.toString() ??
      '';
}

Inquilino? inquilinoForQuota(Quota quota, List<Inquilino> inquilini) {
  final id = quotaUserId(quota);
  for (final inquilino in inquilini) {
    if (inquilino.id == id) return inquilino;
  }
  return null;
}

String inquilinoDisplayName(Inquilino inquilino) {
  final username = inquilino.username.trim();
  if (username.isNotEmpty) return username;
  return inquilino.email.trim().isEmpty ? 'Coinquilino' : inquilino.email;
}

Inquilino? currentSpeseInquilino(
  List<Inquilino> inquilini,
  AuthUser? currentUser,
) {
  final id = currentUser?.id.trim();
  final email = currentUser?.email.trim().toLowerCase();
  for (final inquilino in inquilini) {
    if (id != null && id.isNotEmpty && inquilino.id == id) return inquilino;
    if (email != null &&
        email.isNotEmpty &&
        inquilino.email.trim().toLowerCase() == email) {
      return inquilino;
    }
  }
  return null;
}

String quotaDisplayName(Quota quota, List<Inquilino> inquilini) {
  final inquilino = inquilinoForQuota(quota, inquilini);
  if (inquilino != null) return inquilinoDisplayName(inquilino);
  if (quota.utenteNome.trim().isNotEmpty) return quota.utenteNome.trim();
  final raw = quota.raw;
  final utente = raw['utente'];
  return raw['username']?.toString() ??
      (utente is Map ? utente['username']?.toString() : null) ??
      'Coinquilino';
}

String partecipanteDisplayName(Map<String, dynamic> partecipante) {
  final utente = partecipante['utente'];
  if (utente is Map) {
    final username = utente['username']?.toString().trim();
    if (username != null && username.isNotEmpty) return username;
  }
  return partecipante['username']?.toString() ?? 'Coinquilino';
}

Set<String> selectedParticipantIds(
  Spesa spesa,
  List<Quota> quote,
  List<Inquilino> inquilini,
) {
  final quotaIds = quote.map(quotaUserId).where((id) => id.isNotEmpty).toSet();
  if (quotaIds.isNotEmpty) return quotaIds;

  final ids = <String>{};
  for (final partecipante in spesa.partecipanti) {
    final utente = partecipante['utente'];
    final id =
        partecipante['id'] ??
        partecipante['utenteId'] ??
        partecipante['idUtente'] ??
        partecipante['inquilinoId'] ??
        partecipante['idInquilino'] ??
        (utente is Map ? utente['id'] : null);
    if (id != null) ids.add(id.toString());
  }
  return ids.isEmpty ? inquilini.map((item) => item.id).toSet() : ids;
}

class SpesaQuotaRow {
  const SpesaQuotaRow({
    required this.name,
    required this.initials,
    required this.isPaid,
    required this.isExcluded,
    required this.isCurrentUser,
    required this.userId,
    this.quotaId,
  });

  final String name;
  final String initials;
  final bool isPaid;
  final bool isExcluded;
  final bool isCurrentUser;
  final String userId;
  final String? quotaId;
}

class SpesaDetailProjection {
  const SpesaDetailProjection({
    required this.rows,
    required this.rowsIncludingExcluded,
    required this.payerNames,
    required this.payingNames,
    required this.quotaPerPersona,
    required this.hasAnyPaidQuota,
  });

  factory SpesaDetailProjection.from({
    required Spesa spesa,
    required List<Quota> quote,
    required List<Inquilino> inquilini,
    required String? currentUserId,
  }) {
    final rows = <SpesaQuotaRow>[];
    if (quote.isNotEmpty) {
      for (final quota in quote) {
        final inquilino = inquilinoForQuota(quota, inquilini);
        final id = inquilino?.id ?? quotaUserId(quota);
        final isCurrent = id.isNotEmpty && id == currentUserId;
        final displayName = quotaDisplayName(quota, inquilini);
        rows.add(
          SpesaQuotaRow(
            name: isCurrent ? '$displayName (Tu)' : displayName,
            initials: _initials(displayName),
            isPaid: quota.pagata,
            isExcluded: false,
            isCurrentUser: isCurrent,
            quotaId: quota.id,
            userId: id,
          ),
        );
      }
    } else {
      for (final partecipante in spesa.partecipanti) {
        final name = partecipanteDisplayName(partecipante);
        rows.add(
          SpesaQuotaRow(
            name: name,
            initials: _initials(name),
            isPaid:
                partecipante['pagato'] == true ||
                partecipante['pagata'] == true ||
                partecipante['saldato'] == true,
            isExcluded: partecipante['escluso'] == true,
            isCurrentUser: false,
            userId: '',
          ),
        );
      }
    }

    final includedIds = rows
        .where((row) => row.userId.isNotEmpty)
        .map((row) => row.userId)
        .toSet();
    final allRows = [...rows];
    if (quote.isNotEmpty) {
      for (final inquilino in inquilini) {
        if (includedIds.contains(inquilino.id)) continue;
        final name = inquilinoDisplayName(inquilino);
        allRows.add(
          SpesaQuotaRow(
            name: name,
            initials: _initials(name),
            isPaid: false,
            isExcluded: true,
            isCurrentUser: false,
            userId: inquilino.id,
          ),
        );
      }
    }

    final included = rows.where((row) => !row.isExcluded).toList();
    final unpaidNames = included
        .where((row) => !row.isPaid)
        .map((row) => row.name)
        .toList(growable: false);
    return SpesaDetailProjection(
      rows: List.unmodifiable(rows),
      rowsIncludingExcluded: List.unmodifiable(allRows),
      payerNames: unpaidNames,
      payingNames: unpaidNames.isEmpty ? 'Nessuno' : unpaidNames.join(', '),
      quotaPerPersona: included.isEmpty
          ? spesa.importo
          : spesa.importo / included.length,
      hasAnyPaidQuota: rows.any((row) => row.isPaid),
    );
  }

  final List<SpesaQuotaRow> rows;
  final List<SpesaQuotaRow> rowsIncludingExcluded;
  final List<String> payerNames;
  final String payingNames;
  final double quotaPerPersona;
  final bool hasAnyPaidQuota;
}

bool _isCurrentUserPartecipante(
  Map<String, dynamic> item,
  AuthUser? currentUser,
) {
  final userId = currentUser?.id.trim();
  final email = currentUser?.email.trim().toLowerCase();
  final utente = item['utente'];
  if (utente is Map) {
    if (userId != null &&
        (utente['id']?.toString() == userId ||
            utente['utenteId']?.toString() == userId)) {
      return true;
    }
    if (email != null && utente['email']?.toString().toLowerCase() == email) {
      return true;
    }
  }
  return (userId != null &&
          (item['utenteId']?.toString() == userId ||
              item['idUtente']?.toString() == userId)) ||
      (email != null && item['email']?.toString().toLowerCase() == email);
}

class SpeseViewModel extends FamilyAsyncNotifier<SpeseState, String> {
  ISpeseRepository get _repository => ref.read(speseRepositoryProvider);
  ICasaRepository get _casaRepository => ref.read(casaRepositoryProvider);

  GetSpeseUseCase get _getSpese => GetSpeseUseCase(_repository);
  GetSpesaByIdUseCase get _getSpesaById => GetSpesaByIdUseCase(_repository);
  CreateSpesaUseCase get _createSpesa => CreateSpesaUseCase(_repository);
  UpdateSpesaUseCase get _updateSpesa => UpdateSpesaUseCase(_repository);
  DeleteSpesaUseCase get _deleteSpesa => DeleteSpesaUseCase(_repository);
  GetQuoteSpesaUseCase get _getQuoteSpesa => GetQuoteSpesaUseCase(_repository);
  PagaQuotaUseCase get _pagaQuota => PagaQuotaUseCase(_repository);
  PareggiaContiUseCase get _pareggiaConti => PareggiaContiUseCase(_repository);
  GetSaldoUseCase get _getSaldo => GetSaldoUseCase(_repository);
  GetCreditoTotaleUseCase get _getCreditoTotale =>
      GetCreditoTotaleUseCase(_repository);
  GetDebitoTotaleUseCase get _getDebitoTotale =>
      GetDebitoTotaleUseCase(_repository);
  GetCreditoVersoUseCase get _getCreditoVerso =>
      GetCreditoVersoUseCase(_repository);
  GetDebitoVersoUseCase get _getDebitoVerso =>
      GetDebitoVersoUseCase(_repository);
  GetInquiliniUseCase get _getInquilini => GetInquiliniUseCase(_casaRepository);

  Future<SpeseState> _fetchAll(String casaId) async {
    final spese = await _getSpese(casaId);
    final saldo = await _getSaldo(casaId);
    final creditoTotale = await _getCreditoTotale(casaId);
    final debitoTotale = await _getDebitoTotale(casaId);
    final inquilini = await _getInquilini(casaId);
    return SpeseState(
      spese: spese,
      saldo: saldo,
      creditoTotale: creditoTotale,
      debitoTotale: debitoTotale,
      inquilini: inquilini,
    );
  }

  @override
  Future<SpeseState> build(String casaId) async {
    final timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!state.hasValue) return;
      try {
        state = AsyncData(await _fetchAll(casaId));
      } catch (_) {}
    });
    ref.onDispose(timer.cancel);

    return _fetchAll(casaId);
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

  Future<Spesa> createSpesaFromFields({
    required String descrizione,
    required String importo,
    required Set<String> partecipanti,
    required DateTime data,
    required String? currentUserId,
    bool anticipataPerTutti = false,
    bool ricorrente = false,
    String frequenza = 'Mensile',
  }) {
    return createSpesa(
      _buildPayload(
        importo: _parsePositiveAmount(importo),
        descrizione: descrizione.trim().isEmpty ? 'Spesa' : descrizione,
        selectedIds: partecipanti,
        currentUserId: currentUserId,
        dataSpesa: data,
        hoAnticipatoPerTutti: anticipataPerTutti,
        spesaRicorrente: ricorrente,
        frequenza: frequenza,
      ),
    );
  }

  Future<Spesa> updateSpesa(
    String idSpesa,
    Map<String, dynamic> payload,
  ) async {
    final spesa = await _updateSpesa(arg, idSpesa, payload);
    ref.invalidateSelf();
    return spesa;
  }

  Future<Spesa> updateSpesaFromFields({
    required String idSpesa,
    required String descrizione,
    required String importo,
    required Set<String> partecipanti,
    required DateTime data,
    required String? currentUserId,
    required bool anticipataPerTutti,
    required bool ricorrente,
    required String frequenza,
  }) {
    final payload = _buildPayload(
      importo: _parsePositiveAmount(importo),
      descrizione: descrizione,
      selectedIds: partecipanti,
      currentUserId: currentUserId,
      dataSpesa: data,
      hoAnticipatoPerTutti: anticipataPerTutti,
      spesaRicorrente: ricorrente,
      frequenza: frequenza,
    );
    if (!anticipataPerTutti) payload['anticipataDa'] = null;
    return updateSpesa(idSpesa, payload);
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

final memberSpeseDataProvider = FutureProvider.autoDispose
    .family<MemberSpeseData?, String?>((ref, selectedCasaId) async {
      final caseUtente = await ref.watch(listaCaseViewModelProvider.future);
      if (caseUtente.isEmpty) return null;
      final casa = caseUtente.firstWhere(
        (item) => item.id == selectedCasaId,
        orElse: () => caseUtente.first,
      );
      final state = await ref.watch(speseViewModelProvider(casa.id).future);
      return MemberSpeseData(
        casa: casa,
        spese: state.spese,
        totaleMese: state.saldo,
        credito: state.creditoTotale,
        debito: state.debitoTotale,
      );
    });

class MemberSpeseData {
  const MemberSpeseData({
    required this.casa,
    required this.spese,
    required this.totaleMese,
    required this.credito,
    required this.debito,
  });

  final Casa casa;
  final List<Spesa> spese;
  final double totaleMese;
  final double credito;
  final double debito;

  Map<DateTime, List<Spesa>> get groupedSpese {
    final grouped = <DateTime, List<Spesa>>{};
    for (final spesa in spese) {
      final key = DateTime(spesa.data.year, spesa.data.month);
      grouped.putIfAbsent(key, () => []).add(spesa);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => b.data.compareTo(a.data));
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.unmodifiable(Map.fromEntries(entries));
  }
}

final pareggiaDataProvider = FutureProvider.autoDispose
    .family<PareggiaData?, String?>((ref, selectedCasaId) async {
      final caseUtente = await ref.watch(listaCaseViewModelProvider.future);
      if (caseUtente.isEmpty) return null;
      final casa = caseUtente.firstWhere(
        (item) => item.id == selectedCasaId,
        orElse: () => caseUtente.first,
      );
      final state = await ref.watch(speseViewModelProvider(casa.id).future);
      final notifier = ref.read(speseViewModelProvider(casa.id).notifier);
      final currentUser = await ref.watch(authViewModelProvider.future);
      final balances = <BalanceRow>[];

      for (final inquilino in state.inquilini) {
        final isCurrentUser = _matchesUser(inquilino, currentUser);
        var credito = 0.0;
        var debito = 0.0;
        if (!isCurrentUser) {
          final results = await Future.wait<double>([
            notifier.getCreditoVerso(inquilino.id).catchError((_) => 0.0),
            notifier.getDebitoVerso(inquilino.id).catchError((_) => 0.0),
          ]);
          credito = results[0];
          debito = results[1];
        }
        final name = _inquilinoDisplayName(inquilino);
        balances.add(
          BalanceRow(
            id: inquilino.id,
            name: name,
            initials: _initials(name),
            credito: credito,
            debito: debito,
            isCurrentUser: isCurrentUser,
          ),
        );
      }

      final aggregateSaldo = balances
          .where((row) => !row.isCurrentUser)
          .fold<double>(0, (sum, row) => sum + row.saldo);
      final currentIndex = balances.indexWhere((row) => row.isCurrentUser);
      if (currentIndex != -1) {
        final current = balances[currentIndex];
        balances[currentIndex] = BalanceRow(
          id: current.id,
          name: current.name,
          initials: current.initials,
          credito: aggregateSaldo > 0 ? aggregateSaldo : 0,
          debito: aggregateSaldo < 0 ? aggregateSaldo.abs() : 0,
          isCurrentUser: true,
        );
      }

      balances.sort((a, b) {
        if (a.isCurrentUser) return -1;
        if (b.isCurrentUser) return 1;
        return a.name.compareTo(b.name);
      });
      final current = balances.where((row) => row.isCurrentUser).firstOrNull;
      final transfers = balances
          .where((row) => !row.isCurrentUser && row.debito > row.credito + 0.01)
          .map(
            (row) => TransferRow(
              creditorId: row.id,
              creditorName: row.name,
              creditorInitials: row.initials,
              debtorName: current?.name ?? 'Tu',
              debtorInitials: current?.initials ?? 'T',
              amount: row.debito,
            ),
          )
          .toList(growable: false);
      return PareggiaData(
        casa: casa,
        balances: List.unmodifiable(balances),
        transfers: transfers,
      );
    });

class PareggiaData {
  const PareggiaData({
    required this.casa,
    required this.balances,
    required this.transfers,
  });

  final Casa casa;
  final List<BalanceRow> balances;
  final List<TransferRow> transfers;
}

class BalanceRow {
  const BalanceRow({
    required this.id,
    required this.name,
    required this.initials,
    required this.credito,
    required this.debito,
    required this.isCurrentUser,
  });

  final String id;
  final String name;
  final String initials;
  final double credito;
  final double debito;
  final bool isCurrentUser;

  double get saldo => credito - debito;
}

class TransferRow {
  const TransferRow({
    required this.creditorId,
    required this.creditorName,
    required this.creditorInitials,
    required this.debtorName,
    required this.debtorInitials,
    required this.amount,
  });

  final String creditorId;
  final String creditorName;
  final String creditorInitials;
  final String debtorName;
  final String debtorInitials;
  final double amount;
}

String _inquilinoDisplayName(Inquilino inquilino) {
  final username = inquilino.username.trim();
  if (username.isNotEmpty) return username;
  return inquilino.email.trim().isEmpty ? 'Coinquilino' : inquilino.email;
}

bool _matchesUser(Inquilino inquilino, AuthUser? user) {
  final userId = user?.id.trim();
  if (userId != null && userId.isNotEmpty) return inquilino.id == userId;
  final email = user?.email.trim().toLowerCase();
  return email != null &&
      email.isNotEmpty &&
      inquilino.email.trim().toLowerCase() == email;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

final speseCreateCasaProvider = FutureProvider.family<Casa?, String?>((
  ref,
  selectedCasaId,
) async {
  final caseUtente = await ref.watch(listaCaseViewModelProvider.future);
  if (caseUtente.isEmpty) return null;
  if (selectedCasaId != null && selectedCasaId.isNotEmpty) {
    for (final casa in caseUtente) {
      if (casa.id == selectedCasaId) return casa;
    }
  }
  return caseUtente.first;
});

final speseCreateInquiliniProvider =
    FutureProvider.family<List<Inquilino>, String?>((ref, casaId) async {
      if (casaId == null || casaId.isEmpty) return const [];
      final state = await ref.watch(speseViewModelProvider(casaId).future);
      return state.inquilini;
    });

final speseCreateFormProvider =
    StateNotifierProvider.autoDispose<
      SpesaCreateFormController,
      SpesaCreateFormState
    >((ref) => SpesaCreateFormController(ref));

final modificaSpesaFormProvider =
    StateNotifierProvider.autoDispose<
      SpesaEditFormController,
      SpesaEditFormState
    >((ref) => SpesaEditFormController(ref));

final spesaEditInquiliniProvider = FutureProvider.autoDispose
    .family<List<Inquilino>, String>((ref, casaId) async {
      final state = await ref.watch(speseViewModelProvider(casaId).future);
      return state.inquilini;
    });

class SpesaCreateResult {
  const SpesaCreateResult({
    required this.spesa,
    required this.importo,
    required this.numeroPartecipanti,
    required this.anticipatoreNome,
  });

  final Spesa spesa;
  final double importo;
  final int numeroPartecipanti;
  final String anticipatoreNome;
}

class SpesaCreateFormState {
  const SpesaCreateFormState({
    this.importo = '',
    this.descrizione = '',
    this.selectedInquiliniIds = const {},
    this.currentUserId,
    this.dataSpesa,
    this.hoAnticipatoPerTutti = false,
    this.spesaRicorrente = false,
    this.frequenza = 'Mensile',
    this.showErrors = false,
    this.isSubmitting = false,
    this.submitError = '',
  });

  final String importo;
  final String descrizione;
  final Set<String> selectedInquiliniIds;
  final String? currentUserId;
  final DateTime? dataSpesa;
  final bool hoAnticipatoPerTutti;
  final bool spesaRicorrente;
  final String frequenza;
  final bool showErrors;
  final bool isSubmitting;
  final String submitError;

  DateTime get effectiveDate => dataSpesa ?? DateTime.now();

  double? get parsedImporto {
    final value = double.tryParse(importo.trim().replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  bool get hasValidImporto => parsedImporto != null;

  bool get canSubmit =>
      hasValidImporto &&
      descrizione.trim().isNotEmpty &&
      selectedInquiliniIds.isNotEmpty &&
      !isSubmitting;

  bool get showMissingError => submitError.isNotEmpty && showErrors;

  SpesaCreateFormState copyWith({
    String? importo,
    String? descrizione,
    Set<String>? selectedInquiliniIds,
    String? currentUserId,
    DateTime? dataSpesa,
    bool clearDataSpesa = false,
    bool? hoAnticipatoPerTutti,
    bool? spesaRicorrente,
    String? frequenza,
    bool? showErrors,
    bool? isSubmitting,
    String? submitError,
  }) {
    return SpesaCreateFormState(
      importo: importo ?? this.importo,
      descrizione: descrizione ?? this.descrizione,
      selectedInquiliniIds: selectedInquiliniIds ?? this.selectedInquiliniIds,
      currentUserId: currentUserId ?? this.currentUserId,
      dataSpesa: clearDataSpesa ? null : (dataSpesa ?? this.dataSpesa),
      hoAnticipatoPerTutti: hoAnticipatoPerTutti ?? this.hoAnticipatoPerTutti,
      spesaRicorrente: spesaRicorrente ?? this.spesaRicorrente,
      frequenza: frequenza ?? this.frequenza,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError ?? this.submitError,
    );
  }
}

class SpesaCreateFormController extends StateNotifier<SpesaCreateFormState> {
  SpesaCreateFormController(this._ref) : super(const SpesaCreateFormState());

  final Ref _ref;

  void setImporto(String value) =>
      state = state.copyWith(importo: value, submitError: '');
  void setDescrizione(String value) =>
      state = state.copyWith(descrizione: value, submitError: '');
  void setDataSpesa(DateTime value) => state = state.copyWith(dataSpesa: value);
  void clearDataSpesa() => state = state.copyWith(clearDataSpesa: true);
  void setHoAnticipatoPerTutti(bool value) =>
      state = state.copyWith(hoAnticipatoPerTutti: value);
  void setSpesaRicorrente(bool value) =>
      state = state.copyWith(spesaRicorrente: value);
  void setFrequenza(String value) => state = state.copyWith(frequenza: value);

  void prepopulateInquilini(List<Inquilino> inquilini, String? currentUserId) {
    if (state.selectedInquiliniIds.isNotEmpty && state.currentUserId != null) {
      return;
    }
    state = state.copyWith(
      selectedInquiliniIds: inquilini.map((item) => item.id).toSet(),
      currentUserId: currentUserId,
    );
  }

  void toggleInquilino(String id) {
    if (id == state.currentUserId) return;
    final ids = {...state.selectedInquiliniIds};
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    state = state.copyWith(selectedInquiliniIds: ids, submitError: '');
  }

  Future<SpesaCreateResult?> submit({
    required Casa? casa,
    required List<Inquilino> inquilini,
    required AuthUser? currentUser,
  }) async {
    if (!_validate()) return null;
    if (casa == null || casa.id.isEmpty) {
      _setSubmitError('Nessuna casa disponibile.');
      return null;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final currentUserId = resolveCurrentUserId(inquilini, currentUser);
      final payload = _buildPayload(
        importo: state.parsedImporto!,
        descrizione: state.descrizione,
        selectedIds: state.selectedInquiliniIds,
        currentUserId: currentUserId,
        dataSpesa: state.dataSpesa,
        hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
        spesaRicorrente: state.spesaRicorrente,
        frequenza: state.frequenza,
      );
      final spesa = await _ref
          .read(speseViewModelProvider(casa.id).notifier)
          .createSpesa(payload);
      final partecipanti = payload['partecipanti'] as List<String>;
      return SpesaCreateResult(
        spesa: spesa,
        importo: state.parsedImporto!,
        numeroPartecipanti: partecipanti.length,
        anticipatoreNome: currentUser?.displayName.split(' ').first ?? '',
      );
    } catch (_) {
      _setSubmitError('Impossibile salvare la spesa. Riprova.');
      return null;
    }
  }

  bool _validate() {
    if (!state.canSubmit) {
      _setSubmitError('Dati mancanti: compila i campi necessari');
      return false;
    }
    return true;
  }

  void _setSubmitError(String message) {
    state = state.copyWith(
      submitError: message,
      showErrors: true,
      isSubmitting: false,
    );
  }
}

class SpesaEditFormState {
  const SpesaEditFormState({
    this.importo = '',
    this.descrizione = '',
    this.selectedInquiliniIds = const {},
    this.creatoreId,
    this.dataSpesa,
    this.hoAnticipatoPerTutti = false,
    this.spesaRicorrente = false,
    this.frequenza = 'Mensile',
    this.showErrors = false,
    this.isSubmitting = false,
    this.submitError = '',
    this.casa,
    this.spesaId,
  });

  final String importo;
  final String descrizione;
  final Set<String> selectedInquiliniIds;
  final String? creatoreId;
  final DateTime? dataSpesa;
  final bool hoAnticipatoPerTutti;
  final bool spesaRicorrente;
  final String frequenza;
  final bool showErrors;
  final bool isSubmitting;
  final String submitError;
  final Casa? casa;
  final String? spesaId;

  DateTime get effectiveDate => dataSpesa ?? DateTime.now();

  double? get parsedImporto {
    final value = double.tryParse(importo.trim().replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  bool get hasValidImporto => parsedImporto != null;
  bool get canSubmit =>
      hasValidImporto &&
      descrizione.trim().isNotEmpty &&
      selectedInquiliniIds.isNotEmpty &&
      !isSubmitting &&
      casa != null;
  bool get showMissingError => submitError.isNotEmpty && showErrors;

  SpesaEditFormState copyWith({
    String? importo,
    String? descrizione,
    Set<String>? selectedInquiliniIds,
    String? creatoreId,
    DateTime? dataSpesa,
    bool clearDataSpesa = false,
    bool? hoAnticipatoPerTutti,
    bool? spesaRicorrente,
    String? frequenza,
    bool? showErrors,
    bool? isSubmitting,
    String? submitError,
    Casa? casa,
    String? spesaId,
  }) {
    return SpesaEditFormState(
      importo: importo ?? this.importo,
      descrizione: descrizione ?? this.descrizione,
      selectedInquiliniIds: selectedInquiliniIds ?? this.selectedInquiliniIds,
      creatoreId: creatoreId ?? this.creatoreId,
      dataSpesa: clearDataSpesa ? null : (dataSpesa ?? this.dataSpesa),
      hoAnticipatoPerTutti: hoAnticipatoPerTutti ?? this.hoAnticipatoPerTutti,
      spesaRicorrente: spesaRicorrente ?? this.spesaRicorrente,
      frequenza: frequenza ?? this.frequenza,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError ?? this.submitError,
      casa: casa ?? this.casa,
      spesaId: spesaId ?? this.spesaId,
    );
  }
}

class SpesaEditFormController extends StateNotifier<SpesaEditFormState> {
  SpesaEditFormController(this._ref) : super(const SpesaEditFormState());

  final Ref _ref;

  void initFromSpesa(Spesa spesa, String? currentUserId, Casa casa) {
    final selectedIds = spesa.partecipanti
        .map(
          (item) =>
              item['id']?.toString() ??
              item['idUtente']?.toString() ??
              item['userId']?.toString() ??
              '',
        )
        .where((id) => id.isNotEmpty)
        .toSet();
    if (spesa.creatoreId.isNotEmpty) selectedIds.add(spesa.creatoreId);
    if (currentUserId != null && currentUserId.isNotEmpty) {
      selectedIds.add(currentUserId);
    }

    final cadenza = spesa.raw['cadenzaGiorni'];
    final anticipataDa = spesa.raw['anticipataDa'];
    state = state.copyWith(
      importo: spesa.importo > 0
          ? spesa.importo.toStringAsFixed(2).replaceAll('.', ',')
          : '',
      descrizione: spesa.descrizione,
      dataSpesa: spesa.dataScadenza,
      selectedInquiliniIds: selectedIds,
      creatoreId: spesa.creatoreId.isNotEmpty
          ? spesa.creatoreId
          : currentUserId,
      hoAnticipatoPerTutti:
          anticipataDa != null && anticipataDa.toString().isNotEmpty,
      spesaRicorrente: spesa.isRicorrente,
      frequenza: _frequenzaFromCadenza(cadenza),
      casa: casa,
      spesaId: spesa.id,
    );
  }

  void setImporto(String value) =>
      state = state.copyWith(importo: value, submitError: '');
  void setDescrizione(String value) =>
      state = state.copyWith(descrizione: value, submitError: '');
  void setDataSpesa(DateTime value) => state = state.copyWith(dataSpesa: value);
  void clearDataSpesa() => state = state.copyWith(clearDataSpesa: true);
  void setHoAnticipatoPerTutti(bool value) =>
      state = state.copyWith(hoAnticipatoPerTutti: value);
  void setSpesaRicorrente(bool value) =>
      state = state.copyWith(spesaRicorrente: value);
  void setFrequenza(String value) => state = state.copyWith(frequenza: value);

  void toggleInquilino(String id) {
    if (id == state.creatoreId) return;
    final ids = {...state.selectedInquiliniIds};
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    state = state.copyWith(selectedInquiliniIds: ids, submitError: '');
  }

  Future<Spesa?> submit({
    required List<Inquilino> inquilini,
    required AuthUser? currentUser,
  }) async {
    if (!_validate() || state.casa == null || state.spesaId == null) {
      return null;
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final currentUserId = resolveCurrentUserId(inquilini, currentUser);
      final payload = _buildPayload(
        importo: state.parsedImporto!,
        descrizione: state.descrizione,
        selectedIds: state.selectedInquiliniIds,
        currentUserId: currentUserId,
        dataSpesa: state.dataSpesa,
        hoAnticipatoPerTutti: state.hoAnticipatoPerTutti,
        spesaRicorrente: state.spesaRicorrente,
        frequenza: state.frequenza,
      );
      return await _ref
          .read(speseViewModelProvider(state.casa!.id).notifier)
          .updateSpesa(state.spesaId!, payload);
    } catch (_) {
      _setSubmitError('Impossibile salvare le modifiche. Riprova.');
      return null;
    }
  }

  bool _validate() {
    if (!state.canSubmit) {
      _setSubmitError('Dati mancanti: compila i campi necessari');
      return false;
    }
    return true;
  }

  void _setSubmitError(String message) {
    state = state.copyWith(
      submitError: message,
      showErrors: true,
      isSubmitting: false,
    );
  }
}

String? resolveCurrentUserId(List<Inquilino> inquilini, AuthUser? currentUser) {
  final userId = currentUser?.id.trim();
  if (userId != null && userId.isNotEmpty) return userId;

  final email = currentUser?.email.trim().toLowerCase();
  if (email != null && email.isNotEmpty) {
    for (final inquilino in inquilini) {
      if (inquilino.email.trim().toLowerCase() == email) return inquilino.id;
    }
  }

  final username = currentUser?.username.trim().toLowerCase();
  if (username != null && username.isNotEmpty) {
    for (final inquilino in inquilini) {
      if (inquilino.username.trim().toLowerCase() == username) {
        return inquilino.id;
      }
    }
  }
  return null;
}

Map<String, dynamic> _buildPayload({
  required double importo,
  required String descrizione,
  required Set<String> selectedIds,
  required String? currentUserId,
  required DateTime? dataSpesa,
  required bool hoAnticipatoPerTutti,
  required bool spesaRicorrente,
  required String frequenza,
}) {
  final partecipanti = <String>{...selectedIds};
  if (currentUserId != null && currentUserId.isNotEmpty) {
    partecipanti.add(currentUserId);
  }
  return {
    'descrizione': descrizione.trim(),
    'importo': importo,
    'partecipanti': partecipanti.toList(growable: false),
    'isRicorrente': spesaRicorrente,
    if (dataSpesa != null) 'dataScadenza': _formatDate(dataSpesa),
    if (hoAnticipatoPerTutti && currentUserId != null)
      'anticipataDa': currentUserId,
    if (spesaRicorrente) ...{
      'dataScadenza': _formatDate(dataSpesa ?? DateTime.now()),
      'cadenzaGiorni': _cadenzaGiorniFor(frequenza),
    },
  };
}

int _cadenzaGiorniFor(String frequenza) => switch (frequenza) {
  'Bimestrale' => 60,
  'Trimestrale' => 90,
  'Annuale' => 365,
  _ => 30,
};

String _frequenzaFromCadenza(dynamic cadenza) {
  final value = cadenza is num
      ? cadenza.toInt()
      : int.tryParse('$cadenza') ?? 30;
  return switch (value) {
    60 => 'Bimestrale',
    90 => 'Trimestrale',
    365 => 'Annuale',
    _ => 'Mensile',
  };
}

String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

double _parsePositiveAmount(String value) {
  final amount = double.tryParse(value.trim().replaceAll(',', '.'));
  if (amount == null || amount <= 0) {
    throw const FormatException('Importo non valido.');
  }
  return amount;
}
