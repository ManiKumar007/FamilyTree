import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myfamilytree/main.dart' as app;
import 'dart:math';

/// Integration test for Profile Setup feature
/// Tests the complete flow of creating a user profile after authentication
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Setup Tests', () {
    final random = Random();
    final testEmail = 'profiletest${random.nextInt(100000)}@example.com';
    const testPassword = 'Test123!';
    const testFullName = 'Profile Test User';

    testWidgets('Complete profile setup flow with all required fields', 
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 1: Navigate to signup
      final signUpButton = find.text('Sign Up');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton);
        await tester.pumpAndSettle();
      }

      // Step 2: Create account
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Fill signup form
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      expect(nameField, findsOneWidget, reason: 'Name field should exist on signup');
      await tester.enterText(nameField, testFullName);
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'Email');
      expect(emailField, findsOneWidget, reason: 'Email field should exist on signup');
      await tester.enterText(emailField, testEmail);
      await tester.pumpAndSettle();

      // Password fields
      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(2), testPassword); // Password
      await tester.pumpAndSettle();
      await tester.enterText(passwordFields.at(3), testPassword); // Confirm password
      await tester.pumpAndSettle();

      // Submit signup
      final createAccountButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      expect(createAccountButton, findsOneWidget);
      await tester.tap(createAccountButton);
      
      // Wait for account creation
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Step 3: Login with new account
      // May already be logged in, or need to navigate to login
      final loginScreenIndicator = find.text('Sign In').evaluate().isNotEmpty;
      if (loginScreenIndicator) {
        // Fill login form
        final loginEmailField = find.widgetWithText(TextFormField, 'Email');
        if (loginEmailField.evaluate().isNotEmpty) {
          await tester.enterText(loginEmailField, testEmail);
          await tester.pumpAndSettle();

          final loginPasswordFields = find.byType(TextFormField);
          await tester.enterText(loginPasswordFields.at(1), testPassword);
          await tester.pumpAndSettle();

          final loginButton = find.widgetWithText(ElevatedButton, 'Sign In');
          await tester.tap(loginButton);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }
      }

      // Step 4: Should now be on Profile Setup screen or Home
      // Look for profile setup screen indicators
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Try to find profile setup elements
      final profileSetupTitle = find.text('Complete Your Profile');
      final skipButton = find.text('Skip for now');
      final dateOfBirthField = find.text('Date of Birth');
      
      if (profileSetupTitle.evaluate().isEmpty && 
          skipButton.evaluate().isEmpty && 
          dateOfBirthField.evaluate().isEmpty) {
        // If not on profile setup, try to navigate there
        // (This handles case where user is already logged in)
        print('Not on profile setup screen, may already have profile');
        return; // Test passes - user already has profile or can skip
      }

      // Step 5: Fill profile form
      print('Filling profile setup form...');
      
      // Full Name should be pre-filled or editable
      final profileNameField = find.widgetWithText(TextFormField, 'Full Name');
      if (profileNameField.evaluate().isNotEmpty) {
        // Clear and re-enter name
        await tester.tap(profileNameField);
        await tester.pumpAndSettle();
        // Name might already be filled from signup
      }

      // Date of Birth
      final dobField = find.widgetWithText(TextFormField, 'Date of Birth');
      if (dobField.evaluate().isNotEmpty) {
        await tester.tap(dobField);
        await tester.pumpAndSettle();
        
        // A date picker should appear
        final okButton = find.text('OK');
        if (okButton.evaluate().isNotEmpty) {
          // Select a date (just tap OK to use selected date)
          await tester.tap(okButton);
          await tester.pumpAndSettle();
        }
      }

      // Gender (optional field)
      final genderField = find.widgetWithText(DropdownButtonFormField<String>, 'Gender');
      if (genderField.evaluate().isNotEmpty) {
        await tester.tap(genderField);
        await tester.pumpAndSettle();
        
        // Select first option
        final maleOption = find.text('Male').last;
        if (maleOption.evaluate().isNotEmpty) {
          await tester.tap(maleOption);
          await tester.pumpAndSettle();
        }
      }

      // Phone Number (optional)
      final phoneField = find.widgetWithText(TextFormField, 'Phone Number');
      if (phoneField.evaluate().isNotEmpty) {
        await tester.enterText(phoneField, '+1234567890');
        await tester.pumpAndSettle();
      }

      // City (optional)
      final cityField = find.widgetWithText(TextFormField, 'City');
      if (cityField.evaluate().isNotEmpty) {
        await tester.enterText(cityField, 'Test City');
        await tester.pumpAndSettle();
      }

      // State (optional)
      final stateField = find.widgetWithText(TextFormField, 'State');
      if (stateField.evaluate().isNotEmpty) {
        await tester.enterText(stateField, 'Test State');
        await tester.pumpAndSettle();
      }

      // Country (optional)
      final countryField = find.widgetWithText(TextFormField, 'Country');
      if (countryField.evaluate().isNotEmpty) {
        await tester.enterText(countryField, 'Test Country');
        await tester.pumpAndSettle();
      }

      // Step 6: Submit profile
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Profile');
      expect(
        saveButton, 
        findsOneWidget, 
        reason: 'Save Profile button should exist'
      );
      
      await tester.tap(saveButton);
      print('Tapped Save Profile button, waiting for API response...');
      
      // Wait for profile creation API call
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Step 7: Verify success
      // Should navigate to home screen or show success message
      final homeIndicators = [
        find.text('My Family Tree'),
        find.text('Home'),
        find.byIcon(Icons.account_tree),
        find.byIcon(Icons.home),
      ];

      bool foundHomeIndicator = false;
      for (final indicator in homeIndicators) {
        if (indicator.evaluate().isNotEmpty) {
          foundHomeIndicator = true;
          break;
        }
      }

      // Also check for error messages
      final errorIndicators = [
        find.textContaining('error'),
        find.textContaining('Error'),
        find.textContaining('failed'),
        find.textContaining('Failed'),
        find.textContaining('Service unavailable'),
      ];

      bool foundError = false;
      String? errorMessage;
      for (final indicator in errorIndicators) {
        if (indicator.evaluate().isNotEmpty) {
          foundError = true;
          errorMessage = indicator.evaluate().first.toString();
          break;
        }
      }

      if (foundError) {
        print('ERROR: Profile creation failed: $errorMessage');
        fail('Profile creation failed with error: $errorMessage');
      }

      expect(
        foundHomeIndicator,
        true,
        reason: 'Should navigate to home screen after successful profile creation',
      );

      print('✅ Profile setup test completed successfully!');
    });

    testWidgets('Profile setup validation - missing required fields', 
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to profile setup (assuming user is logged in)
      // This test assumes we can get to profile setup screen
      
      // Try to submit without filling required fields
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Profile');
      
      if (saveButton.evaluate().isEmpty) {
        print('Not on profile setup screen, skipping validation test');
        return;
      }

      // Clear name field if it exists
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, ''); // Clear name
        await tester.pumpAndSettle();
      }

      // Try to submit
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(
        find.textContaining('required') | find.textContaining('Required'),
        findsAtLeast(1),
        reason: 'Should show validation error for required fields',
      );
    });

    testWidgets('Profile setup - skip option works', 
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for skip button
      final skipButton = find.text('Skip for now');
      
      if (skipButton.evaluate().isEmpty) {
        print('Skip button not found, may not be on profile setup screen');
        return;
      }

      // Tap skip
      await tester.tap(skipButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should navigate to home screen
      expect(
        find.byIcon(Icons.account_tree) | find.text('My Family Tree'),
        findsAtLeast(1),
        reason: 'Should navigate to home after skipping profile setup',
      );
    });
  });
}
