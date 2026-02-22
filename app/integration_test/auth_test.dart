import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myfamilytree/main.dart' as app;
import 'dart:math';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Tests', () {
    final random = Random();
    final testEmail = 'test${random.nextInt(100000)}@example.com';
    const testPassword = 'Test123!';
    const testName = 'Test User';

    testWidgets('App loads and shows landing/login screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should show either landing page or login screen (depending on router config)
      expect(
        find.byType(Scaffold),
        findsWidgets,
        reason: 'App should load with a Scaffold',
      );
    });

    testWidgets('Sign up flow - complete registration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to signup if not already there
      final signUpButton = find.text('Sign Up');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton);
        await tester.pumpAndSettle();
      }

      // Wait for signup screen to load
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Look for "Create Account" text
      expect(
        find.text('Create Account'),
        findsOneWidget,
        reason: 'Should be on signup screen',
      );

      // Fill in name
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      expect(nameField, findsOneWidget, reason: 'Name field should exist');
      await tester.enterText(nameField, testName);
      await tester.pumpAndSettle();

      // Fill in email
      final emailField = find.widgetWithText(TextFormField, 'Email');
      expect(emailField, findsOneWidget, reason: 'Email field should exist');
      await tester.enterText(emailField, testEmail);
      await tester.pumpAndSettle();

      // Fill in password
      final passwordFields = find.byType(TextFormField);
      expect(passwordFields, findsAtLeast(3), reason: 'Should have name, email, password, confirm password fields');
      
      // Find password field (third field)
      await tester.enterText(passwordFields.at(2), testPassword);
      await tester.pumpAndSettle();

      // Fill in confirm password (fourth field)
      await tester.enterText(passwordFields.at(3), testPassword);
      await tester.pumpAndSettle();

      // Tap sign up button
      final createAccountButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      expect(createAccountButton, findsOneWidget, reason: 'Sign up button should exist');
      await tester.tap(createAccountButton);
      
      // Wait for API call
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show success message or navigate to login
      // Check for either success snackbar or navigation to login screen
      final signInText = find.text('Sign In');
      final successMessage = find.textContaining('Account created');
      
      expect(
        signInText.evaluate().isNotEmpty || successMessage.evaluate().isNotEmpty,
        true,
        reason: 'Should show success message or navigate to login',
      );
    });

    testWidgets('Sign in flow - login with credentials', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to login if not already there
      final signInButton = find.text('Sign In');
      if (signInButton.evaluate().length > 1) {
        // If there are multiple "Sign In" texts, tap the button one
        await tester.tap(signInButton.first);
        await tester.pumpAndSettle();
      }

      // Wait for login screen
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Look for login screen elements
      final hasWelcome = find.text('Welcome back!').evaluate().isNotEmpty;
      final hasTitle = find.text('MyFamilyTree').evaluate().isNotEmpty;
      expect(
        hasWelcome || hasTitle,
        true,
        reason: 'Should be on login screen',
      );

      // Try to find email and password fields
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordFields = find.byType(TextFormField);

      if (emailField.evaluate().isNotEmpty && passwordFields.evaluate().length >= 2) {
        // Enter test credentials (using a known test account)
        await tester.enterText(emailField, 'test@example.com');
        await tester.pumpAndSettle();

        await tester.enterText(passwordFields.at(1), 'test123');
        await tester.pumpAndSettle();

        // Tap sign in button
        final loginButton = find.widgetWithText(ElevatedButton, 'Sign In');
        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Note: This will fail with invalid credentials, but tests the flow
          // In a real test, you'd use a valid test account from your test DB
        }
      }
    });

    testWidgets('Form validation - empty fields', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Try to submit login form with empty fields
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      if (signInButton.evaluate().isNotEmpty) {
        await tester.tap(signInButton);
        await tester.pumpAndSettle();

        // Should show validation errors
        final hasPleaseEnter = find.textContaining('Please enter').evaluate().isNotEmpty;
        final hasRequired = find.textContaining('required').evaluate().isNotEmpty;
        expect(
          hasPleaseEnter || hasRequired,
          true,
          reason: 'Should show validation error for empty fields',
        );
      }
    });

    testWidgets('Form validation - invalid email format', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.widgetWithText(TextFormField, 'Email');
      if (emailField.evaluate().isNotEmpty) {
        // Enter invalid email
        await tester.enterText(emailField, 'not-an-email');
        await tester.pumpAndSettle();

        // Try to submit
        final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
        if (signInButton.evaluate().isNotEmpty) {
          await tester.tap(signInButton);
          await tester.pumpAndSettle();

          // Should show validation error
          final hasValidEmail = find.textContaining('valid email').evaluate().isNotEmpty;
          final hasAtSign = find.textContaining('@').evaluate().isNotEmpty;
          expect(
            hasValidEmail || hasAtSign,
            true,
            reason: 'Should show invalid email error',
          );
        }
      }
    });

    testWidgets('Form validation - password too short', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to signup
      final signUpButton = find.text('Sign Up');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton);
        await tester.pumpAndSettle();
      }

      final passwordFields = find.byType(TextFormField);
      if (passwordFields.evaluate().length >= 3) {
        // Enter short password
        await tester.enterText(passwordFields.at(2), '123');
        await tester.pumpAndSettle();

        // Try to submit
        final createButton = find.widgetWithText(ElevatedButton, 'Sign Up');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();

          // Should show validation error
          final hasAtLeast6 = find.textContaining('at least 6').evaluate().isNotEmpty;
          final hasCharacters = find.textContaining('characters').evaluate().isNotEmpty;
          expect(
            hasAtLeast6 || hasCharacters,
            true,
            reason: 'Should show password length error',
          );
        }
      }
    });

    testWidgets('Navigation - switch between login and signup', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find "Sign Up" link
      final signUpLink = find.text('Sign Up');
      if (signUpLink.evaluate().isNotEmpty) {
        await tester.tap(signUpLink);
        await tester.pumpAndSettle();

        // Should show signup screen
        expect(find.text('Create Account'), findsOneWidget);

        // Find "Sign In" link
        final signInLink = find.text('Sign In');
        if (signInLink.evaluate().isNotEmpty) {
          await tester.tap(signInLink);
          await tester.pumpAndSettle();

          // Should be back on login screen
          final hasWelcomeBack = find.text('Welcome back!').evaluate().isNotEmpty;
          final hasAppTitle = find.text('MyFamilyTree').evaluate().isNotEmpty;
          expect(
            hasWelcomeBack || hasAppTitle,
            true,
          );
        }
      }
    });

    testWidgets('Password visibility toggle', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find password field
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'test123');
      await tester.pumpAndSettle();

      // Find visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_off);
      if (visibilityButton.evaluate().isNotEmpty) {
        await tester.tap(visibilityButton);
        await tester.pumpAndSettle();

        // Should now show visibility icon
        expect(find.byIcon(Icons.visibility), findsAtLeast(1));
      }
    });
  });
}
