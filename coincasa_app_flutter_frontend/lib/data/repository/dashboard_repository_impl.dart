import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/scadenza.dart';
import 'package:coincasa_app/core/models/salute_casa_item.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/domain/entities/dashboard_data.dart';
import 'package:coincasa_app/domain/repositories/i_dashboard_repository.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  const DashboardRepositoryImpl();

  @override
  Future<List<Casa>> getCase() => ApiProvider.casa.list();

  @override
  Future<List<Turno>> getTurni(String casaId) =>
      ApiProvider.turni.list(casaId);

  @override
  Future<List<Turno>> getTurniOggi(String casaId) =>
      ApiProvider.turni.listOggi(casaId);

  @override
  Future<List<SaluteCasaItem>> getSaluteCasa(String casaId) =>
      ApiProvider.turni.saluteCase(casaId);

  @override
  Future<double> getSaldo(String casaId) =>
      ApiProvider.spese.getSaldo(casaId);

  @override
  Future<double> getCredito(String casaId) =>
      ApiProvider.spese.getCreditoTot(casaId);

  @override
  Future<double> getDebito(String casaId) =>
      ApiProvider.spese.getDebitoTot(casaId);

  @override
  Future<List<Spesa>> getSpese(String casaId) =>
      ApiProvider.spese.list(casaId);

  @override
  Future<List<Scadenza>> getScadenze(String casaId) =>
      ApiProvider.scadenze.list(casaId);

  @override
  Future<void> completaTurno(String casaId, String turnoId) =>
      ApiProvider.turni.completa(casaId, turnoId);

  /// Recupera tutti i dati della dashboard in parallelo per minimizzare la latenza.
  @override
  Future<DashboardData> getDashboardData(String casaId) async {
    final results = await Future.wait<dynamic>([
      ApiProvider.turni.list(casaId),
      ApiProvider.turni.listOggi(casaId),
      ApiProvider.turni.saluteCase(casaId),
      ApiProvider.spese.getSaldo(casaId),
      ApiProvider.spese.getCreditoTot(casaId),
      ApiProvider.spese.getDebitoTot(casaId),
      ApiProvider.spese.list(casaId),
    ]);

    List<Scadenza> scadenze = const [];
    try {
      scadenze = await ApiProvider.scadenze.list(casaId);
    } catch (_) {}

    return DashboardData(
      nomeCasa: '',
      caseUtente: const [],
      casaSelezionataId: casaId,
      turni: results[0] as List<Turno>,
      turniOggi: results[1] as List<Turno>,
      saluteCasa: results[2] as List<SaluteCasaItem>,
      saldo: results[3] as double,
      credito: results[4] as double,
      debito: results[5] as double,
      spese: results[6] as List<Spesa>,
      scadenze: scadenze,
    );
  }
}

final dashboardRepositoryProvider = Provider<IDashboardRepository>(
  (_) => const DashboardRepositoryImpl(),
);
