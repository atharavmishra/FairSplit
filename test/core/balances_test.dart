import 'dart:math';

import 'package:fairsplit/core/balances.dart';
import 'package:fairsplit/core/split.dart';
import 'package:fairsplit/models/expense.dart';
import 'package:fairsplit/models/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

Expense expense(Map<String, int> paidBy, Map<String, int> owed) => Expense(
  id: 'e',
  groupId: 'g',
  description: 'x',
  amount: paidBy.values.fold(0, (a, b) => a + b),
  paidBy: paidBy,
  owed: owed,
  splitType: SplitType.exact,
  date: DateTime(2026),
);

void main() {
  test('net balances from expenses and settlements', () {
    final net = netBalances(
      [
        expense({'a': 3000}, {'a': 1000, 'b': 1000, 'c': 1000}),
      ],
      [Settlement(id: 's', groupId: 'g', from: 'b', to: 'a', amount: 1000, date: DateTime(2026))],
    );
    expect(net, {'a': 1000, 'b': 0, 'c': -1000});
  });

  test('simplify chains A->B->C into A->C', () {
    // a owes b 10, b owes c 10.
    final net = netBalances([
      expense({'b': 1000}, {'a': 1000}),
      expense({'c': 1000}, {'b': 1000}),
    ], []);
    expect(simplifyDebts(net), [const Transfer('a', 'c', 1000)]);
  });

  test('settled group has no transfers', () {
    expect(simplifyDebts({'a': 0, 'b': 0}), isEmpty);
  });

  test('random groups: transfers settle everyone in at most n-1 payments', () {
    final rng = Random(42);
    for (var round = 0; round < 200; round++) {
      final people = List.generate(2 + rng.nextInt(8), (i) => 'p$i');
      final expenses = List.generate(1 + rng.nextInt(10), (_) {
        final total = 1 + rng.nextInt(100000);
        final payer = people[rng.nextInt(people.length)];
        final members = people.where((_) => rng.nextBool()).toList();
        if (members.isEmpty) members.add(payer);
        return expense({
          payer: total,
        }, computeSplit(total: total, type: SplitType.equal, members: members));
      });
      final net = netBalances(expenses, []);
      final transfers = simplifyDebts(net);

      expect(transfers.length, lessThanOrEqualTo(people.length - 1));
      final after = Map.of(net);
      for (final t in transfers) {
        expect(t.amount, greaterThan(0));
        after[t.from] = after[t.from]! + t.amount;
        after[t.to] = after[t.to]! - t.amount;
      }
      expect(after.values.every((v) => v == 0), isTrue, reason: 'round $round');
    }
  });
}
