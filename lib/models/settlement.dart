/// A payment from one member to another to settle up.
class Settlement {
  const Settlement({
    required this.id,
    required this.groupId,
    required this.from,
    required this.to,
    required this.amount,
    required this.date,
  });

  final String id;
  final String groupId;
  final String from;
  final String to;

  /// Paise.
  final int amount;
  final DateTime date;

  Map<String, dynamic> toMap() => {'from': from, 'to': to, 'amount': amount, 'date': date};

  factory Settlement.fromMap(String id, String groupId, Map<String, dynamic> m) => Settlement(
        id: id,
        groupId: groupId,
        from: m['from'] as String,
        to: m['to'] as String,
        amount: m['amount'] as int,
        date: m['date'] as DateTime,
      );
}
