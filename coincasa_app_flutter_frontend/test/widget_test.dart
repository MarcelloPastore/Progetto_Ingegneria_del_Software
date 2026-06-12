import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coincasa_app/core/api/api_provider.dart';
import 'package:coincasa_app/core/api/auth_api.dart';
import 'package:coincasa_app/features/auth/auth.dart';

class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super(ApiProvider.client);

  @override
  Future<void> register({
    required String username,
    required String nome,
    required String cognome,
    required String email,
    required String password,
  }) async {
    // Mock successful registration
    return;
  }
}

void main() {
  setUp(() {
    ApiProvider.auth = FakeAuthApi();
  });

  testWidgets('registration opens the check email screen with valid fields', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));

    await tester.enterText(fields.at(0), 'Marco_Rossi');
    await tester.enterText(fields.at(1), 'Marco');
    await tester.enterText(fields.at(2), 'Rossi');
    await tester.enterText(fields.at(3), 'marco@gmail.com');
    await tester.enterText(fields.at(4), 'password123');
    await tester.enterText(fields.at(5), 'password123');

    final submitButton = find.widgetWithText(ElevatedButton, 'Registrati');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Controlla la tua mail!'), findsOneWidget);
    expect(find.text('marco@gmail.com'), findsOneWidget);
  });

  testWidgets('registration shows an error when passwords do not match', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Marco_Rossi');
    await tester.enterText(fields.at(1), 'Marco');
    await tester.enterText(fields.at(2), 'Rossi');
    await tester.enterText(fields.at(3), 'marco@gmail.com');
    await tester.enterText(fields.at(4), 'password123');
    await tester.enterText(fields.at(5), 'password456');

    final submitButton = find.widgetWithText(ElevatedButton, 'Registrati');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.textContaining('Le password non coincidono. Controlla e riprova.'), findsOneWidget);
    expect(find.text('Le password non coincidono *'), findsOneWidget);
    expect(find.text('Controlla la tua mail!'), findsNothing);
  });

  testWidgets('account activated screen is visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountActivatedScreen(email: 'marco@gmail.com')));

    expect(find.text('Account attivato!'), findsOneWidget);
    expect(find.text('Vai al login'), findsOneWidget);
  });
}
