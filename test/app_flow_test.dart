import 'package:fairsplit/auth/demo_auth_service.dart';
import 'package:fairsplit/main.dart';
import 'package:fairsplit/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(DemoAuthService()),
        repositoryFactoryProvider.overrideWithValue(demoRepositories()),
      ],
      child: const FairSplitApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('create group, add expense, see balances and settle', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('No groups yet'), findsOneWidget);

    // Create a group with two friends.
    await tester.tap(find.text('New group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Group name'), 'Goa trip');
    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Atharv');
    for (final name in ['Rahul', 'Priya']) {
      await tester.enterText(find.widgetWithText(TextField, 'Add a member'), name);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }
    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();
    expect(find.text('Goa trip'), findsOneWidget);

    // Add ₹300 paid by me, split equally.
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Dinner');
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '300');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('₹200.00'), findsOneWidget); // you lent

    // Balances tab suggests two payments to me.
    await tester.tap(find.text('Balances'));
    await tester.pumpAndSettle();
    expect(find.text('gets back ₹200.00'), findsOneWidget);
    expect(find.text('Settle'), findsNWidgets(2));

    // Settle one of them.
    await tester.tap(find.text('Settle').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
    expect(find.text('Settle'), findsOneWidget);
    expect(find.text('gets back ₹100.00'), findsOneWidget);
  });

  testWidgets('Google without Firebase shows a message', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('needs Firebase'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('guest sign out asks first and returns to sign-in', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Link Google account'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out of guest account?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsOneWidget);

    // Signing back in works from the fresh stack.
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('No groups yet'), findsOneWidget);
  });

  testWidgets('delete account returns to sign-in', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsOneWidget);
  });
}
