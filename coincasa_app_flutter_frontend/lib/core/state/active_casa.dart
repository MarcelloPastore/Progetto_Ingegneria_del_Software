import 'package:flutter/material.dart';

import 'package:coincasa_app/core/models/casa.dart';

class ActiveCasaController extends ChangeNotifier {
  String? _selectedCasaId;

  String? get selectedCasaId => _selectedCasaId;

  void selectCasa(String casaId) {
    if (_selectedCasaId == casaId) {
      return;
    }

    _selectedCasaId = casaId;
    notifyListeners();
  }

  Casa resolveCasa(List<Casa> caseUtente) {
    if (caseUtente.isEmpty) {
      throw StateError('Nessuna casa disponibile.');
    }

    final selected = caseUtente.firstWhere(
      (casa) => casa.id == _selectedCasaId,
      orElse: () => caseUtente.first,
    );
    _selectedCasaId = selected.id;

    return selected;
  }
}

class ActiveCasaScope extends InheritedNotifier<ActiveCasaController> {
  const ActiveCasaScope({
    super.key,
    required ActiveCasaController controller,
    required super.child,
  }) : super(notifier: controller);

  static ActiveCasaController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ActiveCasaScope>();
    assert(scope != null, 'ActiveCasaScope non trovato nel widget tree.');
    return scope!.notifier!;
  }

  static ActiveCasaController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<ActiveCasaScope>();
    final scope = element?.widget as ActiveCasaScope?;
    assert(scope != null, 'ActiveCasaScope non trovato nel widget tree.');
    return scope!.notifier!;
  }
}
