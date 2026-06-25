import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/salute_casa_item.dart';
import 'package:coincasa_app/data/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/domain/value_objects/ruolo_casa.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';
import 'package:coincasa_app/data/repository/dashboard_repository_impl.dart';
import 'package:coincasa_app/data/models/dashboard_data.dart';
import 'package:coincasa_app/domain/repositories/i_dashboard_repository.dart';
import 'package:coincasa_app/domain/usecases/casa/select_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/dashboard/get_dashboard_data_usecase.dart';
import 'package:coincasa_app/domain/usecases/dashboard/completa_turno_usecase.dart';
import 'package:coincasa_app/domain/usecases/dashboard/get_case_per_dashboard_usecase.dart';

/// Stato immutabile esposto alla View.
class DashboardState {
  const DashboardState({
    required this.data,
    this.isBackgroundRefreshing = false,
    this.completingTurnoIds = const {},
  });

  final DashboardData data;
  final bool isBackgroundRefreshing;
  final Set<String> completingTurnoIds;

  DashboardState copyWith({
    DashboardData? data,
    bool? isBackgroundRefreshing,
    Set<String>? completingTurnoIds,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isBackgroundRefreshing:
          isBackgroundRefreshing ?? this.isBackgroundRefreshing,
      completingTurnoIds: completingTurnoIds ?? this.completingTurnoIds,
    );
  }

  /// Badge di salute casa derivati da turni e salute, ordinati per urgenza.
  List<TurnoSaluteInfo> get houseHealthBadges {
    final saluteMap = {for (final s in data.saluteCasa) s.id: s};
    final badges = data.turni
        .map((turno) {
          final salute = saluteMap[turno.id];
          return TurnoSaluteInfo(
            titolo: _formatCaption(turno.titolo),
            giorniRimanenti: salute?.giorniRimanenti,
          );
        })
        .where((b) => b.titolo.trim().isNotEmpty)
        .toList();

    badges.sort(_compareBadges);
    return badges;
  }

  String _formatCaption(String titolo) {
    final s = titolo.trim();
    return s.isEmpty ? 'Turno' : s;
  }

  static int _colorGroup(TurnoSaluteInfo badge) {
    final giorni = badge.giorniRimanenti;
    if (giorni == null || giorni < -3) return 0;
    if (giorni <= 0) return 1;
    if (giorni <= 2) return 2;
    return 3;
  }

  static int _compareBadges(TurnoSaluteInfo a, TurnoSaluteInfo b) {
    final ga = _colorGroup(a);
    final gb = _colorGroup(b);
    if (ga != gb) return ga.compareTo(gb);
    final da = a.giorniRimanenti;
    final db = b.giorniRimanenti;
    if (da == null && db == null) return 0;
    if (da == null) return -1;
    if (db == null) return 1;
    if (ga <= 1) return db.abs().compareTo(da.abs());
    return da.compareTo(db);
  }

  /// Scadenze e spese in scadenza nel mese corrente, ordinate per data, max 3.
  List<ProssimeScadenzeEntry> get prossimeScadenze {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entries = <ProssimeScadenzeEntry>[];

    final idScadenzeConSpesa = data.spese
        .map((s) => s.idScadenza)
        .whereType<String>()
        .toSet();

    for (final spesa in data.spese) {
      final d = spesa.dataScadenza;
      if (d == null) continue;
      if (d.year == now.year && d.month == now.month) {
        entries.add(
          ProssimeScadenzeEntry(
            nome: spesa.descrizione,
            date: DateTime(d.year, d.month, d.day),
          ),
        );
      }
    }

    for (final sc in data.scadenze) {
      if (idScadenzeConSpesa.contains(sc.id)) continue;
      final d = sc.dataScadenza;
      if (d.year == now.year && d.month == now.month) {
        entries.add(
          ProssimeScadenzeEntry(
            nome: sc.nome,
            date: DateTime(d.year, d.month, d.day),
          ),
        );
      }
    }

    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries.where((e) => !e.date.isBefore(today)).take(3).toList();
  }
}

/// Entità di dominio per mostrare lo stato di salute di un turno.
class TurnoSaluteInfo {
  const TurnoSaluteInfo({required this.titolo, this.giorniRimanenti});

  final String titolo;
  final int? giorniRimanenti;
}

/// Voce per la sezione "Prossime Scadenze" della dashboard.
class ProssimeScadenzeEntry {
  const ProssimeScadenzeEntry({required this.nome, required this.date});

  final String nome;
  final DateTime date;
}

class DashboardViewModel extends AsyncNotifier<DashboardState> {
  late IDashboardRepository _repository;
  late GetDashboardDataUseCase _getDashboardData;
  late CompletaTurnoUseCase _completaTurno;
  late GetCasePerDashboardUseCase _getCase;
  late SelectCasaUseCase _selectCasa;

  @override
  Future<DashboardState> build() async {
    _repository = ref.read(dashboardRepositoryProvider);
    _getDashboardData = GetDashboardDataUseCase(_repository);
    _completaTurno = CompletaTurnoUseCase(_repository);
    _getCase = GetCasePerDashboardUseCase(_repository);
    _selectCasa = SelectCasaUseCase(ref.read(casaRepositoryProvider));

    final timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    ref.onDispose(timer.cancel);

    return _fetch();
  }

  Future<DashboardState> _fetch() async {
    final caseUtente = await _getCase();
    if (caseUtente.isEmpty) {
      throw StateError('Nessuna casa disponibile.');
    }

    final activeCasa = ref.read(activeCasaProvider);
    final casaId = _resolveActiveCasaId(activeCasa, caseUtente);

    // Aggiorna sempre il ruolo tramite il backend per intercettare promozioni
    // e retrocessioni effettuate da un altro utente.
    final storedRuolo = activeCasa.selectedCasaId == casaId
        ? activeCasa.ruoloCasa
        : null;
    final freshRuolo = await _selectCasa(casaId);
    ref.read(activeCasaProvider.notifier).update(
          (s) => s.copyWith(selectedCasaId: casaId, ruoloCasa: freshRuolo),
        );

    // Segnala il cambio di ruolo significativo (Inquilino ↔ Admin) alla UI.
    if (storedRuolo != null && storedRuolo != freshRuolo) {
      final wasAdmin = RuoloCasa.isAdmin(storedRuolo);
      final isAdmin = RuoloCasa.isAdmin(freshRuolo);
      if (wasAdmin != isAdmin) {
        ref.read(ruoloCambiatoProvider.notifier).state = true;
      }
    }

    final casa = caseUtente.firstWhere(
      (c) => c.id == casaId,
      orElse: () => caseUtente.first,
    );
    // Aggiorna l'oggetto Casa nel provider in modo che le altre schermate
    // possano leggerlo senza una chiamata aggiuntiva.
    ref.read(activeCasaProvider.notifier).update(
          (s) => s.copyWith(selectedCasa: casa),
        );

    final data = await _getDashboardData(casa.id);
    return DashboardState(
      data: data.copyWith(
        nomeCasa: _formatNomeCasa(casa),
        caseUtente: caseUtente,
        casaSelezionataId: casa.id,
      ),
    );
  }

  /// Seleziona una casa: aggiorna JWT e sessione tramite il repository,
  /// poi aggiorna lo stato Riverpod e ricarica i dati.
  Future<void> selectCasa(String casaId) async {
    final previousState = state;
    state = const AsyncLoading();
    try {
      final ruolo = await _selectCasa(casaId);
      ref.read(activeCasaProvider.notifier).update(
            (s) => s.copyWith(selectedCasaId: casaId, ruoloCasa: ruolo),
          );
      state = AsyncData(await _fetch());
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Aggiorna i dati in background mantenendo i dati correnti visibili.
  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(current.copyWith(isBackgroundRefreshing: true));
    try {
      final fresh = await _fetch();
      state = AsyncData(fresh);
    } catch (_) {
      state = AsyncData(current.copyWith(isBackgroundRefreshing: false));
    }
  }

  /// Marca un turno come completato e aggiorna lo stato.
  Future<void> completaTurno(String casaId, String turnoId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        completingTurnoIds: {...current.completingTurnoIds, turnoId},
      ),
    );

    try {
      await _completaTurno(casaId, turnoId);
      await refresh();
    } finally {
      final updated = state.valueOrNull;
      if (updated != null) {
        final ids = Set<String>.from(updated.completingTurnoIds)
          ..remove(turnoId);
        state = AsyncData(updated.copyWith(completingTurnoIds: ids));
      }
    }
  }

  /// Priorità: provider Riverpod → JWT ripristinato → prima casa della lista.
  String _resolveActiveCasaId(ActiveCasaState activeCasa, List<Casa> case_) {
    final fromProvider = activeCasa.selectedCasaId?.trim();
    if (fromProvider != null &&
        fromProvider.isNotEmpty &&
        case_.any((c) => c.id == fromProvider)) {
      return fromProvider;
    }
    final fromJwt = ApiProvider.client.currentCasaId?.trim();
    if (fromJwt != null &&
        fromJwt.isNotEmpty &&
        case_.any((c) => c.id == fromJwt)) {
      return fromJwt;
    }
    return case_.first.id;
  }

  String _formatNomeCasa(Casa casa) {
    final nome = casa.nome.trim();
    if (nome.isEmpty) return 'Casa senza nome';
    return nome.toLowerCase().startsWith('casa ') ? nome : 'Casa $nome';
  }

  List<Turno> get turniOggi =>
      state.valueOrNull?.data.turniOggi ?? const [];

  List<SaluteCasaItem> get saluteCasa =>
      state.valueOrNull?.data.saluteCasa ?? const [];
}

final dashboardViewModelProvider =
    AsyncNotifierProvider<DashboardViewModel, DashboardState>(
  DashboardViewModel.new,
);
