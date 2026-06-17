import 'package:coincasa_app/domain/repositories/i_dashboard_repository.dart';

class CompletaTurnoUseCase {
  const CompletaTurnoUseCase(this._repository);

  final IDashboardRepository _repository;

  Future<void> call(String casaId, String turnoId) =>
      _repository.completaTurno(casaId, turnoId);
}
