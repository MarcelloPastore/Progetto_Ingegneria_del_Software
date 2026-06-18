import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/salute_casa_item.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/data/repository/turni_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';
import 'package:coincasa_app/domain/usecases/turni/assegna_turno_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/auto_assegna_turno_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/completa_turno_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/create_turno_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/delete_turno_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/get_salute_casa_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/get_turni_oggi_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/get_turni_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/get_turno_by_id_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/toggle_rotazione_turno_usecase.dart';
import 'package:coincasa_app/domain/usecases/turni/update_turno_usecase.dart';

class TurniState {
  const TurniState({
    required this.turni,
    required this.turniOggi,
    required this.saluteCasa,
  });

  final List<Turno> turni;
  final List<Turno> turniOggi;
  final List<SaluteCasaItem> saluteCasa;
}

class TurniViewModel extends FamilyAsyncNotifier<TurniState, String> {
  late ITurniRepository _repository;
  late GetTurniUseCase _getTurni;
  late GetTurniOggiUseCase _getTurniOggi;
  late GetSaluteCasaUseCase _getSaluteCasa;
  late CreateTurnoUseCase _createTurno;
  late GetTurnoByIdUseCase _getTurnoById;
  late UpdateTurnoUseCase _updateTurno;
  late DeleteTurnoUseCase _deleteTurno;
  late AutoAssegnaTurnoUseCase _autoAssegnaTurno;
  late AssegnaTurnoUseCase _assegnaTurno;
  late ToggleRotazioneTurnoUseCase _toggleRotazioneTurno;
  late CompletaTurnoUseCase _completaTurno;

  @override
  Future<TurniState> build(String casaId) async {
    _repository = ref.read(turniRepositoryProvider);
    _getTurni = GetTurniUseCase(_repository);
    _getTurniOggi = GetTurniOggiUseCase(_repository);
    _getSaluteCasa = GetSaluteCasaUseCase(_repository);
    _createTurno = CreateTurnoUseCase(_repository);
    _getTurnoById = GetTurnoByIdUseCase(_repository);
    _updateTurno = UpdateTurnoUseCase(_repository);
    _deleteTurno = DeleteTurnoUseCase(_repository);
    _autoAssegnaTurno = AutoAssegnaTurnoUseCase(_repository);
    _assegnaTurno = AssegnaTurnoUseCase(_repository);
    _toggleRotazioneTurno = ToggleRotazioneTurnoUseCase(_repository);
    _completaTurno = CompletaTurnoUseCase(_repository);

    final turni = await _getTurni(casaId);
    final turniOggi = await _getTurniOggi(casaId);
    final saluteCasa = await _getSaluteCasa(casaId);

    return TurniState(
      turni: turni,
      turniOggi: turniOggi,
      saluteCasa: saluteCasa,
    );
  }

  Future<Turno> getTurnoById(String idTurno) => _getTurnoById(arg, idTurno);

  Future<Turno> createTurno(Map<String, dynamic> payload) async {
    final turno = await _createTurno(arg, payload);
    ref.invalidateSelf();
    return turno;
  }

  Future<Turno> updateTurno(
    String idTurno,
    Map<String, dynamic> payload,
  ) async {
    final turno = await _updateTurno(arg, idTurno, payload);
    ref.invalidateSelf();
    return turno;
  }

  Future<void> deleteTurno(String idTurno) async {
    await _deleteTurno(arg, idTurno);
    ref.invalidateSelf();
  }

  Future<void> autoAssegnaTurno(String idTurno) async {
    await _autoAssegnaTurno(arg, idTurno);
    ref.invalidateSelf();
  }

  Future<void> assegnaTurno(
    String idTurno,
    Map<String, dynamic> payload,
  ) async {
    await _assegnaTurno(arg, idTurno, payload);
    ref.invalidateSelf();
  }

  Future<void> toggleRotazioneTurno(String idTurno) async {
    await _toggleRotazioneTurno(arg, idTurno);
    ref.invalidateSelf();
  }

  Future<void> completaTurno(String idTurno) async {
    await _completaTurno(arg, idTurno);
    ref.invalidateSelf();
  }

  void refresh() => ref.invalidateSelf();
}

final turniViewModelProvider =
    AsyncNotifierProviderFamily<TurniViewModel, TurniState, String>(
      TurniViewModel.new,
    );
