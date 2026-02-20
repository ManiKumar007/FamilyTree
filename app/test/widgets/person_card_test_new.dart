import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfamilytree/features/tree/widgets/person_card.dart';
import 'package:myfamilytree/models/models.dart';

// Helper function to create test Person instances with required fields
Person testPerson({
  required String id,
  required String name,
  required String gender,
  String? username,
  String? dateOfBirth,
  String? dateOfDeath,
}) {
  return Person(
    id: id,
    name: name,
    gender: gender,
    phone: '',
    username: username,
    dateOfBirth: dateOfBirth,
    dateOfDeath: dateOfDeath,
  );
}

void main() {
  final currentUser = testPerson(
    id: 'current-user',
    name: 'Current User',
    gender: 'male',
    username: 'currentuser',
  );

  final otherPerson = testPerson(
    id: 'other-person',
    name: 'Other Person',
    gender: 'female',
    username: 'otherperson',
  );

  Widget testWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('PersonCard - Basic Display', () {
    testWidgets('should display person name', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget(PersonCard(person: otherPerson)));

      expect(find.text('Other Person'), findsOneWidget);
    });

    testWidgets('should display gender-specific avatar icon when no photo',
        (WidgetTester tester) async {
      final malePerson = testPerson(
        id: 'male-person',
        name: 'Male Person',
        gender: 'male',
      );

      await tester.pumpWidget(testWidget(PersonCard(person: malePerson)));
      // PersonCard shows Icons.person_rounded for male without photo
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });
  });

  group('PersonCard - Quick Access Button', () {
    testWidgets('should show link button for users with username and callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget(PersonCard(
        person: otherPerson,
        onFindConnection: () {},
      )));

      // Should display link icon button (Icons.link_rounded in implementation)
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });

    testWidgets('should NOT show link button for current user',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget(PersonCard(
        person: currentUser,
        isCurrentUser: true,
        onFindConnection: () {},
      )));

      // Should NOT display link icon button for current user
      expect(find.byIcon(Icons.link_rounded), findsNothing);
    });

    testWidgets('should NOT show link button without callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(testWidget(PersonCard(
        person: otherPerson,
        // No onFindConnection callback
      )));

      // Link button should not be shown if callback is null
      expect(find.byIcon(Icons.link_rounded), findsNothing);
    });

    testWidgets('should call onFindConnection when link button tapped',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(testWidget(PersonCard(
        person: otherPerson,
        onFindConnection: () {
          callbackCalled = true;
        },
      )));

      // Tap the link button
      await tester.tap(find.byIcon(Icons.link_rounded));
      await tester.pumpAndSettle();

      expect(callbackCalled, true);
    });
  });

  group('PersonCard - Visual Elements', () {
    testWidgets('should display birth year if available',
        (WidgetTester tester) async {
      final personWithDate = testPerson(
        id: 'person-with-date',
        name: 'Historical Person',
        gender: 'male',
        dateOfBirth: '1920-01-01',
      );

      await tester.pumpWidget(testWidget(PersonCard(person: personWithDate)));

      // PersonCard shows birthYear in format "(1920 -)"
      expect(find.textContaining('1920'), findsOneWidget);
    });
  });

  group('PersonCard - Action Buttons', () {
    testWidgets('should show edit button when onEdit callback provided',
        (WidgetTester tester) async {
      bool editCalled = false;

      await tester.pumpWidget(testWidget(PersonCard(
        person: otherPerson,
        onEdit: () {
          editCalled = true;
        },
      )));

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(editCalled, true);
    });
  });
}
