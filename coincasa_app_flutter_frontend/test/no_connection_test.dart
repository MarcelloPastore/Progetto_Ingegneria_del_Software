import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/api/api_client.dart';
import 'package:coincasa_app/core/widgets/common/no_connection_screen.dart';

/// Adapter che simula un errore di connessione (SocketException).
class FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: const SocketException('Connection refused'),
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('NoConnectionScreen displays all UI elements correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: NoConnectionScreen()),
    );

    expect(
      find.text('Servizio\ntemporaneamente non disponibile'),
      findsOneWidget,
    );
    expect(
      find.text(
        'I nostri server stanno riscontrando problemi tecnici. Riprova tra qualche minuto.',
      ),
      findsOneWidget,
    );
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

    final ctx = tester.element(find.text('Original Screen'));
    Navigator.of(ctx).pushNamed(NoConnectionScreen.routeName);
    await tester.pumpAndSettle();

    expect(find.byType(NoConnectionScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Annulla'));
    await tester.pumpAndSettle();

    expect(find.byType(NoConnectionScreen), findsNothing);
    expect(find.text('Original Screen'), findsOneWidget);
  });

  testWidgets('ApiClient connection error redirects to NoConnectionScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Home Screen')),
        routes: {
          NoConnectionScreen.routeName: (_) => const NoConnectionScreen(),
        },
      ),
    );

    final failingDio = Dio(
      BaseOptions(baseUrl: 'http://localhost:23109/api/v1'),
    )..httpClientAdapter = FailingAdapter();

    final apiClient = ApiClient(
      baseUrl: 'http://localhost:23109/api/v1',
      dio: failingDio,
    );

    // DioException con type connectionError viene rilanciata dopo il trigger del dialog
    expect(
      () async => apiClient.getJson('/test'),
      throwsA(isA<DioException>()),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NoConnectionScreen), findsOneWidget);
  });
}
