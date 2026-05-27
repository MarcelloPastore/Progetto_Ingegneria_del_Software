import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coincasa_app/features/auth/auth.dart';

void main() {
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

    expect(find.textContaining('Alcuni campi'), findsOneWidget);
    expect(find.text('Le password non coincidono *'), findsOneWidget);
    expect(find.text('Controlla la tua mail!'), findsNothing);
  });

  testWidgets('account activated screen is visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountActivatedScreen(email: 'marco@gmail.com')));

    expect(find.text('Account attivato!'), findsOneWidget);
    expect(find.text('Continua'), findsOneWidget);
  });
}
