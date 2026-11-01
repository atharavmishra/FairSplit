import 'package:fairsplit/core/split.dart';
import 'package:flutter_test/flutter_test.dart';

int sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

void main() {
  group('equal', () {
    test('divides evenly', () {
      expect(computeSplit(total: 30000, type: SplitType.equal, members: ['a', 'b', 'c']), {
        'a': 10000,
        'b': 10000,
        'c': 10000,
      });
    });

    test('leftover paise go to earliest members', () {
      final r = computeSplit(total: 10000, type: SplitType.equal, members: ['a', 'b', 'c']);
      expect(r, {'a': 3334, 'b': 3333, 'c': 3333});
      expect(sum(r), 10000);
    });

    test('rejects zero amount and no members', () {
      expect(
        () => computeSplit(total: 0, type: SplitType.equal, members: ['a']),
        throwsA(isA<SplitException>()),
      );
      expect(
        () => computeSplit(total: 100, type: SplitType.equal, members: []),
        throwsA(isA<SplitException>()),
      );
    });
  });

  group('exact', () {
    test('accepts amounts that add up', () {
      expect(
        computeSplit(
          total: 1000,
          type: SplitType.exact,
          members: ['a', 'b'],
          values: {'a': 700, 'b': 300},
        ),
        {'a': 700, 'b': 300},
      );
    });

    test('rejects amounts that do not add up', () {
      expect(
        () => computeSplit(
          total: 1000,
          type: SplitType.exact,
          members: ['a', 'b'],
          values: {'a': 700, 'b': 200},
        ),
        throwsA(isA<SplitException>()),
      );
    });

    test('drops members owing zero', () {
      expect(
        computeSplit(
          total: 1000,
          type: SplitType.exact,
          members: ['a', 'b'],
          values: {'a': 1000, 'b': 0},
        ),
        {'a': 1000},
      );
    });
  });

  group('percent', () {
    test('thirds sum exactly', () {
      final r = computeSplit(
        total: 10000,
        type: SplitType.percent,
        members: ['a', 'b', 'c'],
        values: {'a': 33.34, 'b': 33.33, 'c': 33.33},
      );
      expect(sum(r), 10000);
      expect(r['a'], 3334);
    });

    test('rejects not 100%', () {
      expect(
        () => computeSplit(
          total: 100,
          type: SplitType.percent,
          members: ['a', 'b'],
          values: {'a': 50, 'b': 40},
        ),
        throwsA(isA<SplitException>()),
      );
    });
  });

  group('shares', () {
    test('weights proportionally', () {
      expect(
        computeSplit(
          total: 9000,
          type: SplitType.shares,
          members: ['couple', 'single'],
          values: {'couple': 2, 'single': 1},
        ),
        {'couple': 6000, 'single': 3000},
      );
    });

    test('awkward totals always sum exactly', () {
      for (var total = 1; total < 500; total++) {
        final r = computeSplit(
          total: total,
          type: SplitType.shares,
          members: ['a', 'b', 'c', 'd'],
          values: {'a': 3, 'b': 1, 'c': 1.5, 'd': 7},
        );
        expect(sum(r), total, reason: 'total $total');
      }
    });

    test('rejects all-zero shares', () {
      expect(
        () => computeSplit(total: 100, type: SplitType.shares, members: ['a'], values: {'a': 0}),
        throwsA(isA<SplitException>()),
      );
    });
  });
}
