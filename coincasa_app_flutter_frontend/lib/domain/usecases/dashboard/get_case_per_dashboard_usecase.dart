import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/domain/repositories/i_dashboard_repository.dart';

class GetCasePerDashboardUseCase {
  const GetCasePerDashboardUseCase(this._repository);

  final IDashboardRepository _repository;

  Future<List<Casa>> call() => _repository.getCase();
}
