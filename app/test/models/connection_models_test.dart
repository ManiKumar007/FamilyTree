import 'package:flutter_test/flutter_test.dart';
import 'package:myfamilytree/models/models.dart';

void main() {
  group('CalculatedRelationship', () {
    test('should parse from JSON correctly', () {
      final json = {
        'description': 'paternal grandfather',
        'category': 'extended',
        'generationsUp': 2,
        'generationsDown': 0,
        'isBloodRelation': true,
        'geneticSimilarity': 25.0,
      };

      final relationship = CalculatedRelationship.fromJson(json);

      expect(relationship.description, 'paternal grandfather');
      expect(relationship.category, 'extended');
      expect(relationship.generationsUp, 2);
      expect(relationship.generationsDown, 0);
      expect(relationship.isBloodRelation, true);
      expect(relationship.geneticSimilarity, 25.0);
    });

    test('should handle null genetic similarity', () {
      final json = {
        'description': 'spouse',
        'category': 'non-blood',
        'generationsUp': 0,
        'generationsDown': 0,
        'isBloodRelation': false,
        'geneticSimilarity': null,
      };

      final relationship = CalculatedRelationship.fromJson(json);

      expect(relationship.description, 'spouse');
      expect(relationship.isBloodRelation, false);
      expect(relationship.geneticSimilarity, null);
    });
  });

  group('CommonAncestor', () {
    test('should parse from JSON correctly', () {
      final json = {
        'personId': 'ancestor-123',
        'name': 'John Doe',
        'distanceFromA': 2,
        'distanceFromB': 3,
      };

      final ancestor = CommonAncestor.fromJson(json);

      expect(ancestor.personId, 'ancestor-123');
      expect(ancestor.name, 'John Doe');
      expect(ancestor.distanceFromA, 2);
      expect(ancestor.distanceFromB, 3);
      expect(ancestor.totalDistance, 5);
    });

    test('totalDistance should be sum of both distances', () {
      final ancestor = const CommonAncestor(
        personId: 'test',
        name: 'Test',
        distanceFromA: 4,
        distanceFromB: 6,
      );

      expect(ancestor.totalDistance, 10);
    });
  });

  group('ConnectionPath', () {
    test('should parse from JSON correctly', () {
      final json = {
        'path': [
          {'personId': 'p1', 'name': 'Person 1', 'gender': 'male'},
          {'personId': 'p2', 'name': 'Person 2', 'gender': 'female'},
        ],
        'relationships': [
          {
            'from': 'p1',
            'to': 'p2',
            'type': 'FATHER_OF',
            'label': 'Father of'
          }
        ],
        'depth': 1,
        'calculatedRelationship': {
          'description': 'daughter',
          'category': 'immediate',
          'generationsUp': 0,
          'generationsDown': 1,
          'isBloodRelation': true,
          'geneticSimilarity': 50.0,
        },
      };

      final path = ConnectionPath.fromJson(json);

      expect(path.path.length, 2);
      expect(path.path[0].personId, 'p1');
      expect(path.path[1].name, 'Person 2');
      expect(path.relationships.length, 1);
      expect(path.relationships[0].label, 'Father of');
      expect(path.depth, 1);
      expect(path.calculatedRelationship?.description, 'daughter');
      expect(path.calculatedRelationship?.geneticSimilarity, 50.0);
    });

    test('should handle path without calculated relationship', () {
      final json = {
        'path': [
          {'personId': 'p1', 'name': 'Person 1', 'gender': 'male'},
        ],
        'relationships': [],
        'depth': 0,
      };

      final path = ConnectionPath.fromJson(json);

      expect(path.depth, 0);
      expect(path.calculatedRelationship, null);
    });
  });

  group('ConnectionStatistics', () {
    test('should parse from JSON correctly', () {
      final json = {
        'totalPaths': 3,
        'shortestDistance': 2,
        'longestDistance': 5,
      };

      final stats = ConnectionStatistics.fromJson(json);

      expect(stats.totalPaths, 3);
      expect(stats.shortestDistance, 2);
      expect(stats.longestDistance, 5);
    });
  });

  group('ConnectionResult', () {
    test('should parse successful connection from JSON', () {
      final json = {
        'connected': true,
        'paths': [
          {
            'path': [
              {'personId': 'p1', 'name': 'Alice', 'gender': 'female'},
              {'personId': 'p2', 'name': 'Bob', 'gender': 'male'},
            ],
            'relationships': [
              {
                'from': 'p1',
                'to': 'p2',
                'type': 'MOTHER_OF',
                'label': 'Mother of'
              }
            ],
            'depth': 1,
            'calculatedRelationship': {
              'description': 'son',
              'category': 'immediate',
              'generationsUp': 0,
              'generationsDown': 1,
              'isBloodRelation': true,
              'geneticSimilarity': 50.0,
            },
          }
        ],
        'commonAncestors': [
          {
            'personId': 'ancestor-1',
            'name': 'Grandparent',
            'distanceFromA': 1,
            'distanceFromB': 2,
          }
        ],
        'statistics': {
          'totalPaths': 1,
          'shortestDistance': 1,
          'longestDistance': 1,
        },
        'path': [
          {'personId': 'p1', 'name': 'Alice', 'gender': 'female'},
          {'personId': 'p2', 'name': 'Bob', 'gender': 'male'},
        ],
        'relationships': [
          {
            'from': 'p1',
            'to': 'p2',
            'type': 'MOTHER_OF',
            'label': 'Mother of'
          }
        ],
        'depth': 1,
      };

      final result = ConnectionResult.fromJson(json);

      expect(result.connected, true);
      expect(result.paths.length, 1);
      expect(result.paths[0].path.length, 2);
      expect(result.paths[0].calculatedRelationship?.description, 'son');
      expect(result.commonAncestors.length, 1);
      expect(result.commonAncestors[0].name, 'Grandparent');
      expect(result.statistics.totalPaths, 1);
      
      // Legacy fields
      expect(result.path.length, 2);
      expect(result.depth, 1);
    });

    test('should parse failed connection from JSON', () {
      final json = {
        'connected': false,
        'paths': [],
        'commonAncestors': [],
        'statistics': {
          'totalPaths': 0,
          'shortestDistance': -1,
          'longestDistance': -1,
        },
        'path': [],
        'relationships': [],
        'depth': -1,
      };

      final result = ConnectionResult.fromJson(json);

      expect(result.connected, false);
      expect(result.paths, isEmpty);
      expect(result.commonAncestors, isEmpty);
      expect(result.statistics.totalPaths, 0);
      expect(result.depth, -1);
    });

    test('should handle multiple paths', () {
      final json = {
        'connected': true,
        'paths': [
          {
            'path': [
              {'personId': 'p1', 'name': 'Person 1', 'gender': 'male'}
            ],
            'relationships': [],
            'depth': 2,
          },
          {
            'path': [
              {'personId': 'p1', 'name': 'Person 1', 'gender': 'male'}
            ],
            'relationships': [],
            'depth': 3,
          },
          {
            'path': [
              {'personId': 'p1', 'name': 'Person 1', 'gender': 'male'}
            ],
            'relationships': [],
            'depth': 4,
          },
        ],
        'commonAncestors': [],
        'statistics': {
          'totalPaths': 3,
          'shortestDistance': 2,
          'longestDistance': 4,
        },
        'path': [
          {'personId': 'p1', 'name': 'Person 1', 'gender': 'male'}
        ],
        'relationships': [],
        'depth': 2,
      };

      final result = ConnectionResult.fromJson(json);

      expect(result.paths.length, 3);
      expect(result.statistics.totalPaths, 3);
      expect(result.statistics.shortestDistance, 2);
      expect(result.statistics.longestDistance, 4);
    });
  });
}
