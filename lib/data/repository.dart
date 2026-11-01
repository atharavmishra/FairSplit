import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/settlement.dart';

/// Storage used by the UI. [FirestoreRepository] is the real backend;
/// [InMemoryRepository] lets the app run before Firebase is configured.
abstract class Repository {
  /// The signed-in user's id.
  String get currentUid;

  /// A fresh random id for new documents.
  String newId();

  Stream<List<Group>> watchGroups();
  Stream<Group?> watchGroup(String groupId);
  Stream<List<Expense>> watchExpenses(String groupId);
  Stream<List<Settlement>> watchSettlements(String groupId);

  /// Creates a group with you plus [otherNames] as members.
  Future<String> createGroup({
    required String name,
    required String yourName,
    required List<String> otherNames,
  });

  /// Gives the current user access to a group via its invite code (id).
  Future<void> joinGroup(String groupId);
  Future<void> saveMembers(String groupId, List<Member> members);

  /// Creates the expense, or replaces it if the id already exists.
  Future<void> saveExpense(Expense expense);
  Future<void> deleteExpense(String groupId, String expenseId);
  Future<void> addSettlement(Settlement settlement);
}
