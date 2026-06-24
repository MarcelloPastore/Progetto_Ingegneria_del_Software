import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/turno.dart';
import 'package:coincasa_app/core/state/active_casa.dart';

void main() {
  test('ActiveCasaController stores house and role in StateProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = ActiveCasaController(container);

    controller.setCasaContext(casaId: 'casa-1', ruolo: 'HomeAdmin');

    expect(controller.selectedCasaId, 'casa-1');
    expect(controller.ruoloCasa, 'HomeAdmin');
    expect(controller.isHomeAdmin, isTrue);
    expect(container.read(activeCasaProvider).selectedCasaId, 'casa-1');
  });

  test('selectCasa clears stale role and cached house', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = ActiveCasaController(container);
    const casa = Casa(id: 'casa-1', nome: 'Casa', indirizzo: 'Via Roma');

    controller.setCasaContext(casaId: casa.id, ruolo: 'HomeAdmin');
    controller.resolveCasa(const [casa]);
    controller.selectCasa('casa-2');

    expect(controller.selectedCasaId, 'casa-2');
    expect(controller.ruoloCasa, isNull);
    expect(controller.selectedCasa, isNull);
    expect(controller.isHomeAdmin, isFalse);
  });

  test('resolveCasa keeps the selected house and caches its data', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = ActiveCasaController(container);
    const caseUtente = [
      Casa(id: 'casa-1', nome: 'Prima', indirizzo: 'Via Uno'),
      Casa(id: 'casa-2', nome: 'Seconda', indirizzo: 'Via Due'),
    ];

    controller.selectCasa('casa-2');
    final selected = controller.resolveCasa(caseUtente);

    expect(selected.id, 'casa-2');
    expect(controller.selectedCasa?.nome, 'Seconda');
  });

  test('clear removes the active house and role', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = ActiveCasaController(container);

    controller.setCasaContext(casaId: 'casa-1', ruolo: 'HomeAdmin');
    controller.clear();

    expect(controller.selectedCasaId, isNull);
    expect(controller.ruoloCasa, isNull);
    expect(controller.selectedCasa, isNull);
  });

  test('Turno formats known frequencies with human labels', () {
    expect(
      Turno.fromJson({'id': 't1', 'cadenzaGiorni': 7}).frequenzaLabel,
      'Ogni settimana',
    );
    expect(
      Turno.fromJson({'id': 't2', 'cadenzaGiorni': '30'}).frequenzaLabel,
      'Ogni mese',
    );
  });

  test('Turno parses list DTO id and assignee', () {
    final turno = Turno.fromJson({
      'id': 'turno-1',
      'task': 'Pulizia cucina',
      'assegnatario': {'id': 'utente-1', 'username': 'mario'},
      'dataProssimaPulizia': '2026-06-20T12:00:00.000Z',
    });

    expect(turno.id, 'turno-1');
    expect(turno.assegnatarioId, 'utente-1');
    expect(turno.assegnatarioNome, 'mario');
  });

  test('Turno still parses legacy assegnatarioCorrente objects', () {
    final turno = Turno.fromJson({
      'id': 'turno-2',
      'assegnatarioCorrente': {'id': 'utente-2', 'username': 'luigi'},
    });

    expect(turno.assegnatarioId, 'utente-2');
    expect(turno.assegnatarioNome, 'luigi');
  });
}
