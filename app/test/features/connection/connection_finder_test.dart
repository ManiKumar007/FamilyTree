import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myfamilytree/features/connection/screens/connection_finder_screen.dart';
import 'package:myfamilytree/models/models.dart';
import 'package:myfamilytree/services/api_service.dart';
import 'package:myfamilytree/providers/profile_provider.dart';

// Mock API Service
class MockApiService extends ApiService {
  MockApiService() : super('http://localhost:3000', '');

  ConnectionResult? _mockResult;

  void setMockConnectionResult(ConnectionResult result) {
    _mockResult = result;
  }

  @override
  Future<ConnectionResult> findConnectionByUsername(
      String currentUserId, String targetUsername) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockResult ??
        ConnectionResult(
          connected: false,
          paths: [],
          commonAncestors: [],
          statistics: const ConnectionStatistics(
            totalPaths: 0,
            shortestDistance: -1,
            longestDistance: -1,
          ),
          path: [],
          relationships: [],
          depth: -1,
        );
  }
}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  Widget createTestWidget({String? targetUsername}) {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApi),
        profileProvider.overrideWith((ref) =>
            const Profile(id: 'user-123', username: 'testuser')),
      ],
      child: MaterialApp(
        home: ConnectionFinderScreen(targetUsername: targetUsername),
      ),
    );
  }

  group('ConnectionFinderScreen - UI Elements', () {
    testWidgets('should display title and username input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Find Connection'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(
          find.text('Enter username to find connection'), findsOneWidget);
    });

    testWidgets('should prefill username from query parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(targetUsername: 'johndoe'));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'johndoe');
    });

    testWidgets('should have a search button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  group('ConnectionFinderScreen - Connection Search', () {
    testWidgets('should show loading indicator while searching',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: [
              const Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              const Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: null,
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 1,
          shortestDistance: 1,
          longestDistance: 1,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      // Enter username
      await tester.enterText(find.byType(TextField), 'testuser2');
      await tester.tap(find.byIcon(Icons.search));

      // Pump to show loading
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display connection not found message',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: false,
        paths: [],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 0,
          shortestDistance: -1,
          longestDistance: -1,
        ),
        path: const [],
        relationships: const [],
        depth: -1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'unknown');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No connection found'), findsOneWidget);
      expect(
        find.textContaining('There is no family connection'),
        findsOneWidget,
      );
    });

    testWidgets('should display error message on search failure',
        (WidgetTester tester) async {
      final errorApi = MockApiService();
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(errorApi),
            profileProvider.overrideWith((ref) =>
                const Profile(id: 'user-123', username: 'testuser')),
          ],
          child: const MaterialApp(
            home: ConnectionFinderScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'testuser2');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('ConnectionFinderScreen - Single Path Display', () {
    testWidgets('should display calculated relationship',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: const CalculatedRelationship(
              description: 'son',
              category: 'immediate',
              generationsUp: 0,
              generationsDown: 1,
              isBloodRelation: true,
              geneticSimilarity: 50.0,
            ),
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 1,
          shortestDistance: 1,
          longestDistance: 1,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('son'), findsOneWidget);
      expect(find.textContaining('50.0%'), findsOneWidget);
    });

    testWidgets('should display DNA similarity badge',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: const CalculatedRelationship(
              description: 'daughter',
              category: 'immediate',
              generationsUp: 0,
              generationsDown: 1,
              isBloodRelation: true,
              geneticSimilarity: 50.0,
            ),
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 1,
          shortestDistance: 1,
          longestDistance: 1,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.bloodtype), findsOneWidget);
      expect(find.textContaining('DNA:'), findsOneWidget);
    });

    testWidgets('should display connection path with person names',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice Smith', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'John Doe', gender: 'male', phone: ''),
              Person(id: 'p3', name: 'Bob Johnson', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 2,
            calculatedRelationship: const CalculatedRelationship(
              description: 'grandson',
              category: 'extended',
              generationsUp: 0,
              generationsDown: 2,
              isBloodRelation: true,
              geneticSimilarity: 25.0,
            ),
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 1,
          shortestDistance: 2,
          longestDistance: 2,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice Smith', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'John Doe', gender: 'male', phone: ''),
          Person(id: 'p3', name: 'Bob Johnson', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 2,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
    });
  });

  group('ConnectionFinderScreen - Multiple Paths', () {
    testWidgets('should display path selector with multiple paths',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: null,
          ),
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p3', name: 'Charlie', gender: 'male', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 2,
            calculatedRelationship: null,
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 2,
          shortestDistance: 1,
          longestDistance: 2,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Path 1 of 2'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should switch between paths when arrows clicked',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: const CalculatedRelationship(
              description: 'son',
              category: 'immediate',
              generationsUp: 0,
              generationsDown: 1,
              isBloodRelation: true,
              geneticSimilarity: 50.0,
            ),
          ),
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p3', name: 'Charlie', gender: 'male', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 2,
            calculatedRelationship: const CalculatedRelationship(
              description: 'grandson',
              category: 'extended',
              generationsUp: 0,
              generationsDown: 2,
              isBloodRelation: true,
              geneticSimilarity: 25.0,
            ),
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 2,
          shortestDistance: 1,
          longestDistance: 2,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially on path 1
      expect(find.text('Path 1 of 2'), findsOneWidget);
      expect(find.text('son'), findsOneWidget);

      // Tap forward arrow to go to path 2
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();

      expect(find.text('Path 2 of 2'), findsOneWidget);
      expect(find.text('grandson'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);

      // Tap back arrow to return to path 1
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(find.text('Path 1 of 2'), findsOneWidget);
      expect(find.text('son'), findsOneWidget);
    });

    testWidgets('should display statistics for multiple paths',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: null,
          ),
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p3', name: 'Charlie', gender: 'male', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 3,
            calculatedRelationship: null,
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 2,
          shortestDistance: 1,
          longestDistance: 3,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('2 paths found'), findsOneWidget);
      expect(find.textContaining('Shortest: 1'), findsOneWidget);
      expect(find.textContaining('Longest: 3'), findsOneWidget);
    });
  });

  group('ConnectionFinderScreen - Common Ancestors', () {
    testWidgets('should display common ancestors section',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: null,
          ),
        ],
        commonAncestors: const [
          CommonAncestor(
            id: 'ancestor-1',
            name: 'John Doe',
            distanceFromA: 2,
            distanceFromB: 3,
          ),
          CommonAncestor(
            id: 'ancestor-2',
            name: 'Jane Smith',
            distanceFromA: 3,
            distanceFromB: 3,
          ),
        ],
        statistics: const ConnectionStatistics(
          totalPaths: 1,
          shortestDistance: 1,
          longestDistance: 1,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Common Ancestors'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.textContaining('5 generations'), findsOneWidget);
      expect(find.textContaining('6 generations'), findsOneWidget);
    });
  });

  group('ConnectionFinderScreen - Share Feature', () {
    testWidgets('should display share button when connection found',
        (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: const CalculatedRelationship(
              description: 'son',
              category: 'immediate',
              generationsUp: 0,
              generationsDown: 1,
              isBloodRelation: true,
              geneticSimilarity: 50.0,
            ),
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 1,
          shortestDistance: 1,
          longestDistance: 1,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.text('Share Connection'), findsOneWidget);
    });
  });

  group('ConnectionFinderScreen - Reverse Button', () {
    testWidgets('should display reverse button', (WidgetTester tester) async {
      mockApi.setMockConnectionResult(ConnectionResult(
        connected: true,
        paths: [
          ConnectionPath(
            path: const [
              Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
              Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
            ],
            relationships: const [],
            depth: 1,
            calculatedRelationship: null,
          ),
        ],
        commonAncestors: const [],
        statistics: const ConnectionStatistics(
          totalPaths: 1,
          shortestDistance: 1,
          longestDistance: 1,
        ),
        path: const [
          Person(id: 'p1', name: 'Alice', gender: 'female', phone: ''),
          Person(id: 'p2', name: 'Bob', gender: 'male', phone: ''),
        ],
        relationships: const [],
        depth: 1,
      ));

      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(find.text('Reverse'), findsOneWidget);
    });
  });
}
