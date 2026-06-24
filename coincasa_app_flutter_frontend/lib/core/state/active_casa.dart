import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/domain/value_objects/ruolo_casa.dart';

@immutable
class ActiveCasaState {
  const ActiveCasaState({
    this.selectedCasaId,
    this.ruoloCasa,
    this.selectedCasa,
  });

  final String? selectedCasaId;
  final String? ruoloCasa;
  final Casa? selectedCasa;

  bool get isHomeAdmin => RuoloCasa.isAdmin(ruoloCasa);

  ActiveCasaState copyWith({
    String? selectedCasaId,
    String? ruoloCasa,
    Casa? selectedCasa,
    bool clearRuoloCasa = false,
    bool clearSelectedCasa = false,
  }) {
    return ActiveCasaState(
      selectedCasaId: selectedCasaId ?? this.selectedCasaId,
      ruoloCasa: clearRuoloCasa ? null : ruoloCasa ?? this.ruoloCasa,
      selectedCasa: clearSelectedCasa
          ? null
          : selectedCasa ?? this.selectedCasa,
    );
  }
}

final activeCasaProvider = StateProvider<ActiveCasaState>(
  (ref) => const ActiveCasaState(),
);

/// Segnale one-shot: true se il ruolo dell'utente è cambiato durante una
/// sincronizzazione. La dashboard lo ascolta e reindirizza alla selezione casa.
final ruoloCambiatoProvider = StateProvider<bool>((ref) => false);

class ActiveCasaController {
  ActiveCasaController(this._container);

  final ProviderContainer _container;

  ActiveCasaState get _state => _container.read(activeCasaProvider);

  String? get selectedCasaId => _state.selectedCasaId;

  Casa? get selectedCasa => _state.selectedCasa;

  String? get ruoloCasa => _state.ruoloCasa;

  bool get isHomeAdmin => _state.isHomeAdmin;

  void clear() {
    _container.read(activeCasaProvider.notifier).state =
        const ActiveCasaState();
  }

  void setCasaContext({required String casaId, required String ruolo}) {
    final normalizedCasaId = casaId.trim();
    final normalizedRuolo = ruolo.trim();
    final current = _state;

    _container.read(activeCasaProvider.notifier).state = ActiveCasaState(
      selectedCasaId: normalizedCasaId.isEmpty ? null : normalizedCasaId,
      ruoloCasa: normalizedRuolo.isEmpty ? null : normalizedRuolo,
      selectedCasa: current.selectedCasa?.id == normalizedCasaId
          ? current.selectedCasa
          : null,
    );
  }

  void selectCasa(String casaId) {
    final normalizedCasaId = casaId.trim();
    final current = _state;
    if (current.selectedCasaId == normalizedCasaId) return;

    _container.read(activeCasaProvider.notifier).state = ActiveCasaState(
      selectedCasaId: normalizedCasaId.isEmpty ? null : normalizedCasaId,
    );
  }

  Casa resolveCasa(List<Casa> caseUtente) {
    if (caseUtente.isEmpty) {
      throw StateError('Nessuna casa disponibile.');
    }

    final current = _state;
    final selected = caseUtente.firstWhere(
      (casa) => casa.id == current.selectedCasaId,
      orElse: () => caseUtente.first,
    );

    _container.read(activeCasaProvider.notifier).state = current.copyWith(
      selectedCasaId: selected.id,
      selectedCasa: selected,
    );

    return selected;
  }
}

class ActiveCasaScope extends ConsumerWidget {
  const ActiveCasaScope({super.key, required this.child});

  final Widget child;

  static ActiveCasaController of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<_ActiveCasaInherited>();
    final container = ProviderScope.containerOf(context);
    return ActiveCasaController(container);
  }

  static ActiveCasaController read(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    return ActiveCasaController(container);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeCasaProvider);
    return _ActiveCasaInherited(state: state, child: child);
  }
}

class _ActiveCasaInherited extends InheritedWidget {
  const _ActiveCasaInherited({required this.state, required super.child});

  final ActiveCasaState state;

  @override
  bool updateShouldNotify(_ActiveCasaInherited oldWidget) {
    return state != oldWidget.state;
  }
}
