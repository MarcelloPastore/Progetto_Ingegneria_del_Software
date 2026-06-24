import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/api/casa_api.dart';
import 'package:coincasa_app/core/api/problemi_api.dart';
import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/inquilino.dart';
import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/core/state/active_casa.dart';
import 'package:coincasa_app/ui/problemi/screens/modifica_problema_screen.dart';
import 'package:coincasa_app/ui/problemi/screens/segnala_problema_screen.dart';

const _casa = Casa(
  id: 'casa-1',
  nome: 'Casa test',
  indirizzo: 'Via Test 1',
  ruolo: 'HomeAdmin',
);

class _FakeCasaApi extends CasaApi {
  _FakeCasaApi() : super(ApiProvider.client);

  @override
  Future<List<Casa>> list() async => const [_casa];

  @override
  Future<List<Inquilino>> listInquilini(String casaId) async => const [];
}

class _FakeProblemiApi extends ProblemiApi {
  _FakeProblemiApi() : super(ApiProvider.client);

  int createCalls = 0;
  int updateCalls = 0;
  String? receivedCasaId;
  String? receivedProblemaId;
  @override
  Future<Problema> create(String casaId, Map<String, dynamic> payload) async {
    createCalls++;
    receivedCasaId = casaId;
    return Problema.fromJson({
      'id': 'problema-1',
      ...payload,
      'stato': 'Segnalato',
      'segnalataDa': {'id': 'utente-1', 'username': 'mario'},
      'assegnatario': null,
      'dataCreazione': '2026-06-13T10:00:00.000Z',
      'dataRisoluzione': null,
    });
  }

  @override
  Future<Problema> update(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    updateCalls++;
    receivedCasaId = casaId;
    receivedProblemaId = problemaId;
    return Problema.fromJson({
      'id': problemaId,
      ...payload,
      'stato': 'Segnalato',
      'segnalataDa': {'id': 'utente-1', 'username': 'mario'},
      'assegnatario': null,
      'dataCreazione': '2026-06-13T10:00:00.000Z',
      'dataRisoluzione': null,
    });
  }
}

void main() {
  late CasaApi originalCasaApi;
  late ProblemiApi originalProblemiApi;
  late _FakeProblemiApi problemiApi;

  setUp(() {
    originalCasaApi = ApiProvider.casa;
    originalProblemiApi = ApiProvider.problemi;
    problemiApi = _FakeProblemiApi();
    ApiProvider.casa = _FakeCasaApi();
    ApiProvider.problemi = problemiApi;
    ApiProvider.client.setCasaContext(casaId: _casa.id, ruolo: _casa.ruolo);
  });

  tearDown(() {
    ApiProvider.casa = originalCasaApi;
    ApiProvider.problemi = originalProblemiApi;
    ApiProvider.client.clearCasaContext();
  });

  testWidgets('saving a new problem completes without a Flutter crash', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: ActiveCasaScope(
          child: MaterialApp(home: SegnalaProblemaScreen()),
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Rubinetto rotto');
    await tester.enterText(fields.at(1), 'Perde acqua dalla base');
    await tester.tap(find.text('Media'));
    await tester.tap(find.text('Chiedi a tutti'));
    await tester.ensureVisible(find.text('Segnala problema').last);
    await tester.tap(find.text('Segnala problema').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(problemiApi.createCalls, 1);
    expect(problemiApi.receivedCasaId, _casa.id);
    expect(find.text('Problema segnalato!'), findsOneWidget);
  });

  testWidgets('editing a problem uses the active house and problem ids', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final problema = Problema.fromJson({
      'id': 'problema-1',
      'nome': 'Rubinetto rotto',
      'descrizione': 'Perde acqua',
      'priorita': 'Media',
      'stato': 'Segnalato',
    });

    await tester.pumpWidget(
      ProviderScope(
        child: ActiveCasaScope(
          child: MaterialApp(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              settings: RouteSettings(arguments: problema),
              builder: (_) => const ModificaProblemaScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Salva modifiche'));
    await tester.tap(find.text('Salva modifiche'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(problemiApi.updateCalls, 1);
    expect(problemiApi.receivedCasaId, _casa.id);
    expect(problemiApi.receivedProblemaId, problema.id);
  });

}
