import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/data/models/salute_casa_item.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/data/models/turno.dart';
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
}

final dashboardRepositoryProvider = Provider<IDashboardRepository>(
  (_) => const DashboardRepositoryImpl(),
);
