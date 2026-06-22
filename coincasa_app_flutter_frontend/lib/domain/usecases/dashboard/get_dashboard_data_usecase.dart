import 'package:coincasa_app/data/models/salute_casa_item.dart';
import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/data/models/turno.dart';
import 'package:coincasa_app/domain/entities/dashboard_data.dart';
import 'package:coincasa_app/domain/repositories/i_dashboard_repository.dart';

class GetDashboardDataUseCase {
  const GetDashboardDataUseCase(this._repository);

  final IDashboardRepository _repository;

  Future<DashboardData> call(String casaId) async {
    final results = await Future.wait<dynamic>([
      _repository.getTurni(casaId),
      _repository.getTurniOggi(casaId),
      _repository.getSaluteCasa(casaId),
      _repository.getSaldo(casaId),
      _repository.getCredito(casaId),
      _repository.getDebito(casaId),
      _repository.getSpese(casaId),
    ]);

    List<Scadenza> scadenze = const [];
    try {
      scadenze = await _repository.getScadenze(casaId);
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
