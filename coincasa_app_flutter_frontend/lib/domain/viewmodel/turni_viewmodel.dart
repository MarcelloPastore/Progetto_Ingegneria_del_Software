import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/core/models/auth_user.dart';
import 'package:coincasa_app/core/api/turni_repository_provider.dart';
import 'package:coincasa_app/core/models/casa.dart';
import 'package:coincasa_app/core/models/salute_casa_item.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/data/repository/casa_repository_impl.dart';
import 'package:coincasa_app/domain/repositories/i_casa_repository.dart';
import 'package:coincasa_app/domain/repositories/i_turni_repository.dart';
import 'package:coincasa_app/domain/usecases/casa/get_inquilini_usecase.dart';
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
import 'package:coincasa_app/domain/viewmodel/auth_view_model.dart';
import 'package:coincasa_app/domain/viewmodel/lista_case_viewmodel.dart';

class TurniState {
  const TurniState({
    required this.turni,
    required this.turniOggi,
    required this.saluteCasa,
    required this.inquilini,
  });

  final List<Turno> turni;
  final List<Turno> turniOggi;
  final List<SaluteCasaItem> saluteCasa;
  final List<Inquilino> inquilini;
}

class TurniListProjection {
  const TurniListProjection({required this.scaduti, required this.assegnati});

  factory TurniListProjection.from(List<Turno> turni, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final scaduti = <Turno>[];
    final assegnati = <Turno>[];

    for (final turno in turni) {
      if (turno.completato) continue;
      final date = turno.dataProssimaPulizia;
      if (date == null) {
        assegnati.add(turno);
        continue;
      }
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly.isAfter(today)) {
        assegnati.add(turno);
      } else {
        scaduti.add(turno);
      }
    }

    int compareByDate(Turno a, Turno b) {
      final aDate = a.dataProssimaPulizia;
      final bDate = b.dataProssimaPulizia;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    }

    scaduti.sort(compareByDate);
    assegnati.sort(compareByDate);
    return TurniListProjection(
      scaduti: List.unmodifiable(scaduti),
      assegnati: List.unmodifiable(assegnati),
    );
  }

  final List<Turno> scaduti;
  final List<Turno> assegnati;
}

String assigneeDisplayName(Inquilino inquilino) {
  final username = inquilino.username.trim();
  if (username.isNotEmpty) return username;
  final email = inquilino.email.trim();
  return email.isNotEmpty ? email.split('@').first : 'coinquilino';
}

bool inquilinoMatchesUser(Inquilino inquilino, AuthUser? user) {
  final userId = user?.id.trim();
  if (userId != null && userId.isNotEmpty && inquilino.id.trim() == userId) {
    return true;
  }
  final candidates = <String>{
    inquilino.email.trim().toLowerCase(),
    inquilino.nomeCompleto.trim().toLowerCase(),
    inquilino.nome.trim().toLowerCase(),
    inquilino.username.trim().toLowerCase(),
    assigneeDisplayName(inquilino).trim().toLowerCase(),
  };
  return [user?.email, user?.displayName, user?.nome, user?.cognome]
      .whereType<String>()
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .any(candidates.contains);
}

List<Inquilino> validAssignees(List<Inquilino> inquilini) => inquilini
    .where((inquilino) => inquilino.id.isNotEmpty)
    .toList(growable: false);

Inquilino? currentInquilino(List<Inquilino> inquilini, AuthUser? currentUser) {
  for (final inquilino in inquilini) {
    if (inquilinoMatchesUser(inquilino, currentUser)) return inquilino;
  }
  return null;
}

List<Inquilino> otherAssignees(
  List<Inquilino> inquilini,
  AuthUser? currentUser,
) => inquilini
    .where((inquilino) => !inquilinoMatchesUser(inquilino, currentUser))
    .toList(growable: false);

List<Inquilino> assigneesExceptId(
  List<Inquilino> inquilini,
  String? excludedId,
) => inquilini
    .where((inquilino) => inquilino.id != excludedId)
    .toList(growable: false);

Inquilino? inquilinoById(List<Inquilino> inquilini, String? id) {
  if (id == null || id.isEmpty) return null;
  for (final inquilino in inquilini) {
    if (inquilino.id == id) return inquilino;
  }
  return null;
}

Inquilino? selectedInquilino(List<Inquilino> inquilini, String? selectedId) =>
    inquilinoById(inquilini, selectedId) ?? inquilini.firstOrNull;

String resolveTurnoCreatorName(Turno turno, List<Inquilino> inquilini) {
  final name = turno.creatoreNome.trim();
  if (name.isNotEmpty) return name;
  final creator = inquilinoById(inquilini, turno.creatoreId.trim());
  return creator == null ? '' : assigneeDisplayName(creator);
}

class TurniViewModel extends FamilyAsyncNotifier<TurniState, String> {
  ITurniRepository get _repository => ref.read(turniRepositoryProvider);
  ICasaRepository get _casaRepository => ref.read(casaRepositoryProvider);

  GetTurniUseCase get _getTurni => GetTurniUseCase(_repository);
  GetTurniOggiUseCase get _getTurniOggi => GetTurniOggiUseCase(_repository);
  GetSaluteCasaUseCase get _getSaluteCasa => GetSaluteCasaUseCase(_repository);
  CreateTurnoUseCase get _createTurno => CreateTurnoUseCase(_repository);
  GetTurnoByIdUseCase get _getTurnoById => GetTurnoByIdUseCase(_repository);
  UpdateTurnoUseCase get _updateTurno => UpdateTurnoUseCase(_repository);
  DeleteTurnoUseCase get _deleteTurno => DeleteTurnoUseCase(_repository);
  AutoAssegnaTurnoUseCase get _autoAssegnaTurno =>
      AutoAssegnaTurnoUseCase(_repository);
  AssegnaTurnoUseCase get _assegnaTurno => AssegnaTurnoUseCase(_repository);
  ToggleRotazioneTurnoUseCase get _toggleRotazioneTurno =>
      ToggleRotazioneTurnoUseCase(_repository);
  CompletaTurnoUseCase get _completaTurno => CompletaTurnoUseCase(_repository);
  GetInquiliniUseCase get _getInquilini => GetInquiliniUseCase(_casaRepository);

  @override
  Future<TurniState> build(String casaId) async {
    final turni = await _getTurni(casaId);
    final turniOggi = await _getTurniOggi(casaId);
    final saluteCasa = await _getSaluteCasa(casaId);
    final inquilini = await _getInquilini(casaId);

    return TurniState(
      turni: turni,
      turniOggi: turniOggi,
      saluteCasa: saluteCasa,
      inquilini: inquilini,
    );
  }

  Future<Turno> getTurnoById(String idTurno) => _getTurnoById(arg, idTurno);

  Future<Turno> createTurno(Map<String, dynamic> payload) async {
    final turno = await _createTurno(arg, payload);
    ref.invalidateSelf();
    return turno;
  }

  Future<Turno> createTurnoFromFields({
    required String task,
    required DateTime data,
    required int cadenzaGiorni,
    required String? assegnatarioId,
    required bool rotazioneAutomatica,
  }) {
    final normalizedAssignee = assegnatarioId?.trim();
    return createTurno({
      'task': task.trim(),
      'dataTurno': DateTime(
        data.year,
        data.month,
        data.day,
        12,
      ).toIso8601String(),
      'cadenzaGiorni': cadenzaGiorni,
      if (normalizedAssignee != null && normalizedAssignee.isNotEmpty)
        'assegnatario': normalizedAssignee,
      'rotazioneTurno': rotazioneAutomatica,
    });
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

final listaTurniCasaProvider = FutureProvider.autoDispose
    .family<Casa?, String?>((ref, selectedCasaId) async {
      final caseUtente = await ref.watch(listaCaseViewModelProvider.future);
      if (caseUtente.isEmpty) return null;
      if (selectedCasaId != null && selectedCasaId.isNotEmpty) {
        for (final casa in caseUtente) {
          if (casa.id == selectedCasaId) return casa;
        }
      }
      return caseUtente.first;
    });

final listaTurniProvider = FutureProvider.autoDispose
    .family<List<Turno>, String?>((ref, casaId) async {
      if (casaId == null || casaId.isEmpty) return const [];
      return (await ref.watch(turniViewModelProvider(casaId).future)).turni;
    });

final turniInquiliniProvider = FutureProvider.family<List<Inquilino>, String?>((
  ref,
  casaId,
) async {
  if (casaId == null || casaId.isEmpty) return const [];
  return (await ref.watch(turniViewModelProvider(casaId).future)).inquilini;
});

final turnoCreateFormProvider =
    StateNotifierProvider.autoDispose<
      TurnoCreateFormController,
      TurnoCreateFormState
    >((ref) => TurnoCreateFormController(ref));

class TurnoCreateData {
  const TurnoCreateData({
    required this.casa,
    required this.inquilini,
    required this.currentInquilino,
    this.turno,
  });

  final Casa casa;
  final List<Inquilino> inquilini;
  final Inquilino? currentInquilino;
  final Turno? turno;

  bool get isEditing => turno != null;
  List<Inquilino> get assigneeChoices =>
      inquilini.where((item) => item.id.isNotEmpty).toList(growable: false);
}

class TurnoSubmitResult {
  const TurnoSubmitResult({required this.isEditing});

  final bool isEditing;
}

class TurnoCreateFormState {
  const TurnoCreateFormState({
    this.task = '',
    this.day = '',
    this.month = '',
    this.frequency = 'Ogni settimana',
    this.selectedInquilinoId,
    this.autoRotation = true,
    this.frequencyExpanded = false,
    this.showErrors = false,
    this.isSubmitting = false,
    this.submitError,
    this.allowPastDate = false,
  });

  factory TurnoCreateFormState.today() {
    final now = DateTime.now();
    return TurnoCreateFormState(
      day: now.day.toString().padLeft(2, '0'),
      month: monthLabel(now.month),
    );
  }

  static const frequencies = [
    'Ogni giorno',
    'Ogni 3 giorni',
    'Ogni settimana',
    'Ogni 2 settimane',
    'Ogni mese',
  ];

  static const frequencyDays = {
    'Ogni giorno': 1,
    'Ogni 3 giorni': 3,
    'Ogni settimana': 7,
    'Ogni 2 settimane': 14,
    'Ogni mese': 30,
  };

  final String task;
  final String day;
  final String month;
  final String frequency;
  final String? selectedInquilinoId;
  final bool autoRotation;
  final bool frequencyExpanded;
  final bool showErrors;
  final bool isSubmitting;
  final String? submitError;
  final bool allowPastDate;

  DateTime? get turnoDate => _parseDate(day, month, allowPast: allowPastDate);
  bool get hasValidDate => turnoDate != null;

  bool get isPastDate {
    final parsed = _parseDate(day, month, allowPast: true);
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get showDatePastError => showErrors && isPastDate && !allowPastDate;
  bool get showMissingError =>
      showErrors &&
      submitError == null &&
      (task.trim().isEmpty || !hasValidDate);
  bool get canSubmit =>
      !isSubmitting &&
      task.trim().isNotEmpty &&
      hasValidDate &&
      frequency.isNotEmpty;

  TurnoCreateFormState copyWith({
    String? task,
    String? day,
    String? month,
    String? frequency,
    Object? selectedInquilinoId = _sentinel,
    bool? autoRotation,
    bool? frequencyExpanded,
    bool? showErrors,
    bool? isSubmitting,
    Object? submitError = _sentinel,
    bool? allowPastDate,
  }) {
    return TurnoCreateFormState(
      task: task ?? this.task,
      day: day ?? this.day,
      month: month ?? this.month,
      frequency: frequency ?? this.frequency,
      selectedInquilinoId: selectedInquilinoId == _sentinel
          ? this.selectedInquilinoId
          : selectedInquilinoId as String?,
      autoRotation: autoRotation ?? this.autoRotation,
      frequencyExpanded: frequencyExpanded ?? this.frequencyExpanded,
      showErrors: showErrors ?? this.showErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError == _sentinel
          ? this.submitError
          : submitError as String?,
      allowPastDate: allowPastDate ?? this.allowPastDate,
    );
  }

  static DateTime? _parseDate(
    String dayValue,
    String monthValue, {
    bool allowPast = false,
  }) {
    final day = int.tryParse(dayValue.trim());
    final month = _parseMonth(monthValue);
    if (day == null || month == null) return null;

    final now = DateTime.now();
    final parsed = DateTime(now.year, month, day);
    if (parsed.day != day || parsed.month != month) return null;
    if (allowPast || !parsed.isBefore(DateTime(now.year, now.month, now.day))) {
      return parsed;
    }
    return null;
  }

  static int? _parseMonth(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final numeric = int.tryParse(normalized);
    if (numeric != null && numeric >= 1 && numeric <= 12) return numeric;
    return const {
      'gen': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'mag': 5,
      'giu': 6,
      'lug': 7,
      'ago': 8,
      'set': 9,
      'ott': 10,
      'nov': 11,
      'dic': 12,
    }[normalized];
  }
}

class TurnoCreateFormController extends StateNotifier<TurnoCreateFormState> {
  TurnoCreateFormController(this._ref) : super(TurnoCreateFormState.today());

  final Ref _ref;

  Future<TurnoCreateData?> load({
    required String? selectedCasaId,
    required String? turnoId,
  }) async {
    final caseUtente = await _ref.read(listaCaseViewModelProvider.future);
    if (caseUtente.isEmpty) return null;
    final casa = caseUtente.firstWhere(
      (item) => item.id == selectedCasaId,
      orElse: () => caseUtente.first,
    );

    Turno? turno;
    if (turnoId != null && turnoId.isNotEmpty) {
      try {
        turno = await _ref
            .read(turniViewModelProvider(casa.id).notifier)
            .getTurnoById(turnoId);
      } catch (_) {
        turno = null;
      }
    }

    final turniState = await _ref.read(turniViewModelProvider(casa.id).future);
    final currentUser = await _ref.read(authViewModelProvider.future);
    final currentInquilino = _resolveCurrentInquilino(
      turniState.inquilini,
      currentUser,
    );
    if (turno != null) {
      hydrateFromTurno(turno);
    } else {
      if (currentInquilino != null) setAssignee(currentInquilino.id);
    }

    return TurnoCreateData(
      casa: casa,
      inquilini: turniState.inquilini,
      currentInquilino: currentInquilino,
      turno: turno,
    );
  }

  void hydrateFromTurno(Turno turno) {
    final initialDate = turno.dataProssimaPulizia ?? turno.data;
    state = state.copyWith(
      task: turno.titolo,
      frequency: _frequencyLabelFor(turno.cadenzaGiorni),
      autoRotation: turno.rotazioneAttiva,
      selectedInquilinoId: turno.assegnatarioId.isEmpty
          ? null
          : turno.assegnatarioId,
      allowPastDate: true,
    );
    if (initialDate != null) setPickedDate(initialDate);
  }

  Future<TurnoSubmitResult?> submit(TurnoCreateData? data) async {
    state = state.copyWith(showErrors: true, submitError: null);
    if (!state.canSubmit) return null;
    if (data == null || data.casa.id.isEmpty) {
      _setSubmitError('Nessuna casa disponibile.');
      return null;
    }

    final turnoDate = state.turnoDate;
    if (turnoDate == null) {
      _setSubmitError('Dati mancanti: compila i campi necessari');
      return null;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final payload = <String, dynamic>{
        'task': state.task.trim(),
        'cadenzaGiorni':
            TurnoCreateFormState.frequencyDays[state.frequency] ?? 7,
        'rotazioneTurno': state.autoRotation,
      };
      if (data.isEditing) {
        await _ref
            .read(turniViewModelProvider(data.casa.id).notifier)
            .updateTurno(data.turno!.id, payload);
      } else {
        payload['dataTurno'] = _payloadDate(turnoDate).toIso8601String();
        final assigneeId = state.selectedInquilinoId?.trim();
        if (assigneeId != null && assigneeId.isNotEmpty) {
          payload['assegnatario'] = assigneeId;
        }
        await _ref
            .read(turniViewModelProvider(data.casa.id).notifier)
            .createTurno(payload);
      }
      return TurnoSubmitResult(isEditing: data.isEditing);
    } catch (_) {
      _setSubmitError('Impossibile salvare il turno. Riprova.');
      return null;
    }
  }

  void setTask(String value) =>
      state = state.copyWith(task: value, submitError: null);
  void setDay(String value) =>
      state = state.copyWith(day: value, submitError: null);
  void setMonth(String value) =>
      state = state.copyWith(month: value, submitError: null);
  void setFrequency(String value) => state = state.copyWith(
    frequency: value,
    frequencyExpanded: false,
    submitError: null,
  );
  void setAssignee(String id) =>
      state = state.copyWith(selectedInquilinoId: id, submitError: null);
  void setAutoRotation(bool value) =>
      state = state.copyWith(autoRotation: value);
  void setAllowPastDate(bool value) =>
      state = state.copyWith(allowPastDate: value);
  void toggleFrequency() =>
      state = state.copyWith(frequencyExpanded: !state.frequencyExpanded);
  void setPickedDate(DateTime date) => state = state.copyWith(
    day: date.day.toString().padLeft(2, '0'),
    month: monthLabel(date.month),
    submitError: null,
  );

  void _setSubmitError(String message) {
    state = state.copyWith(
      submitError: message,
      showErrors: true,
      isSubmitting: false,
    );
  }

  static String _frequencyLabelFor(int days) {
    return TurnoCreateFormState.frequencyDays.entries
        .firstWhere(
          (entry) => entry.value == days,
          orElse: () => const MapEntry('Ogni settimana', 7),
        )
        .key;
  }

  static DateTime _payloadDate(DateTime date) =>
      DateTime(date.year, date.month, date.day, 12);
}

Inquilino? _resolveCurrentInquilino(
  List<Inquilino> inquilini,
  AuthUser? currentUser,
) {
  final currentId = currentUser?.id.trim();
  final currentEmail = currentUser?.email.trim().toLowerCase();
  final currentName = currentUser?.displayName.trim().toLowerCase();
  for (final inquilino in inquilini) {
    if (currentId != null &&
        currentId.isNotEmpty &&
        inquilino.id == currentId) {
      return inquilino;
    }
    if (currentEmail != null &&
        currentEmail.isNotEmpty &&
        inquilino.email.trim().toLowerCase() == currentEmail) {
      return inquilino;
    }
    if (currentName != null && currentName.isNotEmpty) {
      final names = {
        inquilino.nomeCompleto.trim().toLowerCase(),
        inquilino.nome.trim().toLowerCase(),
        inquilino.username.trim().toLowerCase(),
      };
      if (names.contains(currentName)) return inquilino;
    }
  }
  return null;
}

String monthLabel(int month) => const [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
][month - 1];

const Object _sentinel = Object();
