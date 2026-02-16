import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Import all test files
import 'auth_test.dart' as auth_tests;
import 'tree_test.dart' as tree_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full Test Suite', () {
    // Run all authentication tests
    auth_tests.main();
    
    // Run all tree tests
    tree_tests.main();
  });
}
