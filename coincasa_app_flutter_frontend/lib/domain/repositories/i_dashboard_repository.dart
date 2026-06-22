import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/data/models/salute_casa_item.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/data/models/turno.dart';

abstract interface class IDashboardRepository {
  Future<List<Casa>> getCase();

  Future<List<Turno>> getTurni(String casaId);

  Future<List<Turno>> getTurniOggi(String casaId);

  Future<List<SaluteCasaItem>> getSaluteCasa(String casaId);

  Future<double> getSaldo(String casaId);

  Future<double> getCredito(String casaId);

  Future<double> getDebito(String casaId);

  Future<List<Spesa>> getSpese(String casaId);

  Future<List<Scadenza>> getScadenze(String casaId);

  Future<void> completaTurno(String casaId, String turnoId);
}
