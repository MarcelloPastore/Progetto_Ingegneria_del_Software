import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/api/api_client.dart';
import 'package:coincasa_app/core/widgets/common/no_connection_screen.dart';

class FailingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw const SocketException('Connection refused');
  }
}

void main() {
  testWidgets('NoConnectionScreen displays all UI elements correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NoConnectionScreen(),
      ),
    );

    // Verify Title
    expect(
      find.text('Servizio\ntemporaneamente non disponibile'),
      findsOneWidget,
    );

    // Verify Subtitle
    expect(
      find.text(
        'I nostri server stanno riscontrando problemi tecnici. Riprova tra qualche minuto.',
      ),
      findsOneWidget,
    );

    // Verify Buttons
    expect(find.widgetWithText(FilledButton, 'Riprova'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Annulla'), findsOneWidget);
  });

  testWidgets('NoConnectionScreen Annulla pops the screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('Original Screen')),
        routes: {
          NoConnectionScreen.routeName: (_) => const NoConnectionScreen(),
        },
      ),
    );

    final BuildContext context = tester.element(find.text('Original Screen'));
    Navigator.of(context).pushNamed(NoConnectionScreen.routeName);
    await tester.pumpAndSettle();

    // Verify NoConnectionScreen is shown
    expect(find.byType(NoConnectionScreen), findsOneWidget);

    // Tap Annulla
    final annullaButton = find.widgetWithText(OutlinedButton, 'Annulla');
    await tester.tap(annullaButton);
    await tester.pumpAndSettle();

    // Verify popped back to Original Screen
    expect(find.byType(NoConnectionScreen), findsNothing);
    expect(find.text('Original Screen'), findsOneWidget);
  });

  testWidgets('ApiClient connection error redirects to NoConnectionScreen', (
    WidgetTester tester,
  ) async {
    // Setup MaterialApp with global navigatorKey
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Home Screen')),
        routes: {
          NoConnectionScreen.routeName: (_) => const NoConnectionScreen(),
        },
      ),
    );

    // Create client with failing http client
    final apiClient = ApiClient(
      baseUrl: 'http://localhost:23109/api/v1',
      httpClient: FailingHttpClient(),
    );

    // Call API and expect it to throw SocketException (rethrow)
    expect(
      () async => await apiClient.getJson('/test'),
      throwsA(isA<SocketException>()),
    );

    // Settle navigator animations
    await tester.pumpAndSettle();

    // Verify that NoConnectionScreen is pushed
    expect(find.byType(NoConnectionScreen), findsOneWidget);
  });
}
