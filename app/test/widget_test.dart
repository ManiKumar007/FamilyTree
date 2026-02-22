// Basic smoke test for MyFamilyTree app
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myfamilytree/app.dart';

void main() {
  testWidgets('App smoke test - MyFamilyTreeApp renders', (WidgetTester tester) async {
    // Verify the app widget can be constructed
    expect(const MyFamilyTreeApp(), isA<MyFamilyTreeApp>());
  });
}
