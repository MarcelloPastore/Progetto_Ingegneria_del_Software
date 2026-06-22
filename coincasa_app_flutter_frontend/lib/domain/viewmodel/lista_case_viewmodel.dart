import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';
import 'package:coincasa_app/domain/usecases/casa/get_case_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/create_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/join_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/select_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/casa/delete_casa_usecase.dart';

class ListaCaseViewModel extends AsyncNotifier<List<Casa>> {
  late ICasaRepository _repository;
  late GetCaseUseCase _getCase;
  late CreateCasaUseCase _createCasa;
  late JoinCasaUseCase _joinCasa;
  late SelectCasaUseCase _selectCasa;
  late DeleteCasaUseCase _deleteCasa;

  @override
  Future<List<Casa>> build() async {
    _repository = ref.read(casaRepositoryProvider);
    _getCase = GetCaseUseCase(_repository);
    _createCasa = CreateCasaUseCase(_repository);
    _joinCasa = JoinCasaUseCase(_repository);
    _selectCasa = SelectCasaUseCase(_repository);
    _deleteCasa = DeleteCasaUseCase(_repository);
    return _getCase();
  }

  Future<Casa> createCasa(Map<String, dynamic> payload) async {
    final casa = await _createCasa(payload);
    ref.invalidateSelf();
    return casa;
  }

  Future<Casa> joinCasa(String inviteCodeOrLink) async {
    final casa = await _joinCasa(inviteCodeOrLink);
    ref.invalidateSelf();
    return casa;
  }

  Future<String> selectCasa(String casaId) => _selectCasa(casaId);

  Future<void> deleteCasa(String casaId) async {
    await _deleteCasa(casaId);
    ref.invalidateSelf();
  }

  void refresh() => ref.invalidateSelf();
}

final listaCaseViewModelProvider =
    AsyncNotifierProvider<ListaCaseViewModel, List<Casa>>(
  ListaCaseViewModel.new,
);
