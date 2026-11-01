import 'money.dart';

enum SplitType {
  equal('Equally'),
  exact('Exact amounts'),
  percent('Percentages'),
  shares('Shares');

  const SplitType(this.label);
  final String label;
}

class SplitException implements Exception {
  SplitException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Works out how much each member owes for an expense of [total] paise.
///
/// [members] are the participants, in a stable order; any leftover paise
/// from rounding go to members earliest in this list.
///
/// [values] depends on [type]:
/// - equal: ignored
/// - exact: paise per member, must add up to [total]
/// - percent: percentage per member, must add up to 100
/// - shares: weight per member (e.g. 2 for a couple), must be > 0 in total
///
/// The result always sums exactly to [total] and omits members owing 0.
Map<String, int> computeSplit({
  required int total,
  required SplitType type,
  required List<String> members,
  Map<String, num> values = const {},
}) {
  if (total <= 0) throw SplitException('Amount must be more than zero');
  if (members.isEmpty) throw SplitException('Pick at least one person');

  final Map<String, int> result;
  switch (type) {
    case SplitType.equal:
      result = _allocate(total, {for (final m in members) m: 1}, members);
    case SplitType.exact:
      result = {for (final m in members) m: (values[m] ?? 0).round()};
      if (result.values.any((v) => v < 0)) {
        throw SplitException('Amounts cannot be negative');
      }
      final sum = result.values.fold(0, (a, b) => a + b);
      if (sum != total) {
        throw SplitException('Amounts add up to ${formatAmount(sum)}, not ${formatAmount(total)}');
      }
    case SplitType.percent:
      final weights = {for (final m in members) m: values[m] ?? 0};
      final sum = weights.values.fold<num>(0, (a, b) => a + b);
      if (weights.values.any((v) => v < 0)) {
        throw SplitException('Percentages cannot be negative');
      }
      if ((sum - 100).abs() > 0.001) {
        throw SplitException('Percentages add up to $sum%, not 100%');
      }
      result = _allocate(total, weights, members);
    case SplitType.shares:
      final weights = {for (final m in members) m: values[m] ?? 0};
      if (weights.values.any((v) => v < 0)) {
        throw SplitException('Shares cannot be negative');
      }
      if (weights.values.fold<num>(0, (a, b) => a + b) <= 0) {
        throw SplitException('Give at least one person a share');
      }
      result = _allocate(total, weights, members);
  }
  result.removeWhere((_, v) => v == 0);
  return result;
}

/// Splits [total] proportionally to [weights] using the largest-remainder
/// method, so the parts are integers that sum exactly to [total].
/// Ties on remainder go to whoever comes first in [order].
Map<String, int> _allocate(int total, Map<String, num> weights, List<String> order) {
  final sum = weights.values.fold<num>(0, (a, b) => a + b);
  final parts = <String, int>{};
  final remainders = <String, double>{};
  var assigned = 0;
  for (final m in order) {
    final exact = total * (weights[m] ?? 0) / sum;
    final floor = exact.floor();
    parts[m] = floor;
    remainders[m] = exact - floor;
    assigned += floor;
  }
  final byRemainder = [...order]
    ..sort((a, b) {
      final cmp = remainders[b]!.compareTo(remainders[a]!);
      return cmp != 0 ? cmp : order.indexOf(a) - order.indexOf(b);
    });
  for (var i = 0; i < total - assigned; i++) {
    final m = byRemainder[i % byRemainder.length];
    parts[m] = parts[m]! + 1;
  }
  return parts;
}
