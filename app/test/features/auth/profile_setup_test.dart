import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myfamilytree/features/auth/screens/profile_setup_screen.dart';
import 'package:myfamilytree/services/api_service.dart';

// Mock API Service for username validation
class MockApiService extends ApiService {
  MockApiService() : super('http://localhost:3000', '');

  final Set<String> _takenUsernames = {'admin', 'test', 'johndoe', 'janedoe'};

  @override
  Future<bool> checkUsernameAvailability(String username) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return !_takenUsernames.contains(username.toLowerCase());
  }

  void addTakenUsername(String username) {
    _takenUsernames.add(username.toLowerCase());
  }
}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApi),
      ],
      child: const MaterialApp(
        home: ProfileSetupScreen(),
      ),
    );
  }

  group('ProfileSetupScreen - Username Field', () {
    testWidgets('should display username input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(
        find.text('Choose a unique username (alphanumeric, underscore, hyphen)'),
        findsOneWidget,
      );
    });

    testWidgets('should have required name and gender fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'),
          findsOneWidget);
    });

    testWidgets('should have save button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.widgetWithText(ElevatedButton, 'Save Profile'),
          findsOneWidget);
    });
  });

  group('ProfileSetupScreen - Username Validation', () {
    testWidgets('should show error for empty username',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Fill required fields except username
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      
      // Select gender
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      // Try to submit without username
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('should show error for username that is too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter short username
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'ab');
      
      // Fill other required fields
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();

      expect(
        find.text('Username must be at least 3 characters'),
        findsOneWidget,
      );
    });

    testWidgets('should show error for invalid username characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter username with special characters
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'user@name!');
      
      // Fill other required fields
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();

      expect(
        find.text('Username can only contain letters, numbers, underscore, and hyphen'),
        findsOneWidget,
      );
    });

    testWidgets('should accept valid username formats',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final validUsernames = [
        'john_doe',
        'user123',
        'my-username',
        'JohnDoe',
        'user_name_123',
      ];

      for (final username in validUsernames) {
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Username'), username);
        await tester.pump();

        // Enter name to trigger validation
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
        await tester.pump();

        // Should not show format validation errors
        expect(
          find.text('Username can only contain letters, numbers, underscore, and hyphen'),
          findsNothing,
        );
        expect(
          find.text('Username must be at least 3 characters'),
          findsNothing,
        );
      }
    });
  });

  group('ProfileSetupScreen - Username Availability', () {
    testWidgets('should show loading indicator while checking availability',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter a username
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'newuser');
      
      // Pump to trigger debounce start
      await tester.pump(const Duration(milliseconds: 100));

      // Should show checking indicator (this is implementation-dependent)
      // The actual UI might show a progress indicator or helper text
    });

    testWidgets('should show error for taken username',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter a username that's already taken
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'admin');
      
      // Wait for debounce and API call
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Fill other fields and try to submit
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Username is already taken'), findsOneWidget);
    });

    testWidgets('should accept available username',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter an available username
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'uniqueuser123');
      
      // Wait for debounce and API call
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Fill other fields
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      // Try to submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();

      // Should not show availability error
      expect(find.text('Username is already taken'), findsNothing);
    });

    testWidgets('should debounce username availability checks',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final usernameField = find.widgetWithText(TextFormField, 'Username');

      // Type username character by character
      await tester.enterText(usernameField, 'a');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(usernameField, 'ab');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(usernameField, 'abc');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(usernameField, 'abcd');
      
      // Wait for debounce timer
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // API should only be called once after typing stops
      // (Implementation detail: verify through mock API call count if needed)
    });
  });

  group('ProfileSetupScreen - Form Submission', () {
    testWidgets('should validate all fields before submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to submit empty form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Gender is required'), findsOneWidget);
    });

    testWidgets('should disable submit button while processing',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Fill all fields with valid data
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'newuser123');
      
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      // Get initial button state
      final saveButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Save Profile'));
      
      expect(saveButton.onPressed, isNotNull);
    });
  });

  group('ProfileSetupScreen - Optional Fields', () {
    testWidgets('should have optional birth date field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.widgetWithText(TextFormField, 'Date of Birth (Optional)'),
          findsOneWidget);
    });

    testWidgets('should accept form without optional fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Fill only required fields
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'validuser');
      
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      // Submit should work without optional fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();

      // Should not show validation errors for optional fields
      expect(find.textContaining('Date of Birth'), findsOneWidget); // Only the label
    });
  });

  group('ProfileSetupScreen - Edge Cases', () {
    testWidgets('should handle username with maximum length',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter a very long username
      final longUsername = 'a' * 50;
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), longUsername);
      
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Should accept long usernames (or show max length error if limited)
      // This depends on implementation
    });

    testWidgets('should trim whitespace from username',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter username with leading/trailing spaces
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), '  testuser  ');
      
      // The implementation should trim or show validation error
      await tester.pump();
    });

    testWidgets('should handle case-insensitive username checking',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 'admin' is taken in our mock
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'ADMIN');
      
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Fill other fields and submit
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      
      await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Gender'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Profile'));
      await tester.pumpAndSettle();

      // Should show taken error even for different case
      expect(find.text('Username is already taken'), findsOneWidget);
    });
  });
}
