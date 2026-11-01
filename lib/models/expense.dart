import '../core/split.dart';

class Expense {
  const Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.owed,
    required this.splitType,
    required this.date,
    this.splitValues = const {},
    this.category = 'general',
  });

  final String id;
  final String groupId;
  final String description;

  /// Total in paise.
  final int amount;

  /// memberId -> paise paid. Supports several payers.
  final Map<String, int> paidBy;

  /// memberId -> paise owed. Output of [computeSplit]; sums to [amount].
  final Map<String, int> owed;

  final SplitType splitType;

  /// The raw inputs used for the split, so the expense can be edited later.
  final Map<String, num> splitValues;
  final String category;
  final DateTime date;

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
        'paidBy': paidBy,
        'owed': owed,
        'splitType': splitType.name,
        'splitValues': splitValues,
        'category': category,
        'date': date,
      };

  factory Expense.fromMap(String id, String groupId, Map<String, dynamic> m) => Expense(
        id: id,
        groupId: groupId,
        description: m['description'] as String,
        amount: m['amount'] as int,
        paidBy: Map<String, int>.from(m['paidBy'] as Map),
        owed: Map<String, int>.from(m['owed'] as Map),
        splitType: SplitType.values.byName(m['splitType'] as String),
        splitValues: Map<String, num>.from((m['splitValues'] as Map?) ?? const {}),
        category: (m['category'] as String?) ?? 'general',
        date: m['date'] as DateTime,
      );
}
