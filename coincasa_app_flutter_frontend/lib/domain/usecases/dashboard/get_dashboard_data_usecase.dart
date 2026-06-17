import 'package:coincasa_app/domain/entities/dashboard_data.dart';
import 'package:coincasa_app/domain/repositories/i_dashboard_repository.dart';

class GetDashboardDataUseCase {
  const GetDashboardDataUseCase(this._repository);

  final IDashboardRepository _repository;

  Future<DashboardData> call(String casaId) =>
      _repository.getDashboardData(casaId);
}
