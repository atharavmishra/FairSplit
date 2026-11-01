import '../models/expense.dart';
import '../models/settlement.dart';

class Transfer {
  const Transfer(this.from, this.to, this.amount);
  final String from;
  final String to;
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is Transfer && other.from == from && other.to == to && other.amount == amount;
  @override
  int get hashCode => Object.hash(from, to, amount);
  @override
  String toString() => '$from -> $to: $amount';
}

/// Net balance per member in paise: positive means the group owes them,
/// negative means they owe the group. Always sums to zero.
Map<String, int> netBalances(Iterable<Expense> expenses, Iterable<Settlement> settlements) {
  final net = <String, int>{};
  void add(String id, int amount) => net[id] = (net[id] ?? 0) + amount;

  for (final e in expenses) {
    e.paidBy.forEach(add);
    e.owed.forEach((id, amount) => add(id, -amount));
  }
  for (final s in settlements) {
    // Paying someone back reduces what you owe and what they're owed.
    add(s.from, s.amount);
    add(s.to, -s.amount);
  }
  return net;
}

/// Turns net balances into the fewest practical payments: repeatedly
/// match the biggest debtor with the biggest creditor. Produces at most
/// n-1 transfers. Deterministic for the same input.
List<Transfer> simplifyDebts(Map<String, int> net) {
  final creditors = <MapEntry<String, int>>[
    for (final e in net.entries)
      if (e.value > 0) MapEntry(e.key, e.value),
  ];
  final debtors = <MapEntry<String, int>>[
    for (final e in net.entries)
      if (e.value < 0) MapEntry(e.key, -e.value),
  ];
  int byAmountThenId(MapEntry<String, int> a, MapEntry<String, int> b) {
    final cmp = b.value.compareTo(a.value);
    return cmp != 0 ? cmp : a.key.compareTo(b.key);
  }

  final transfers = <Transfer>[];
  while (creditors.isNotEmpty && debtors.isNotEmpty) {
    creditors.sort(byAmountThenId);
    debtors.sort(byAmountThenId);
    final c = creditors.first;
    final d = debtors.first;
    final amount = c.value < d.value ? c.value : d.value;
    transfers.add(Transfer(d.key, c.key, amount));

    creditors.removeAt(0);
    debtors.removeAt(0);
    if (c.value > amount) creditors.add(MapEntry(c.key, c.value - amount));
    if (d.value > amount) debtors.add(MapEntry(d.key, d.value - amount));
  }
  return transfers;
}
