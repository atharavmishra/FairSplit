import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/settlement.dart';
import 'repository.dart';

/// Firestore layout:
///   groups/{groupId}                      Group
///   groups/{groupId}/expenses/{id}        Expense
///   groups/{groupId}/settlements/{id}     Settlement
/// Access is controlled by `accessUids` on the group (see firestore.rules).
class FirestoreRepository implements Repository {
  FirestoreRepository(this.currentUid, [FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  final String currentUid;

  CollectionReference<Map<String, dynamic>> get _groups => _db.collection('groups');

  @override
  String newId() => _groups.doc().id;

  /// Firestore returns Timestamps; the models use DateTime.
  static Map<String, dynamic> _dates(Map<String, dynamic> data) => {
    for (final e in data.entries)
      e.key: e.value is Timestamp ? (e.value as Timestamp).toDate() : e.value,
  };

  @override
  Stream<List<Group>> watchGroups() => _groups
      .where('accessUids', arrayContains: currentUid)
      .snapshots()
      // Sorted here rather than with orderBy, which would need a composite index.
      .map(
        (s) =>
            s.docs.map((d) => Group.fromMap(d.id, _dates(d.data()))).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Stream<Group?> watchGroup(String groupId) => _groups
      .doc(groupId)
      .snapshots()
      .map((d) => d.exists ? Group.fromMap(d.id, _dates(d.data()!)) : null);

  @override
  Stream<List<Expense>> watchExpenses(String groupId) => _groups
      .doc(groupId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Expense.fromMap(d.id, groupId, _dates(d.data()))).toList());

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) => _groups
      .doc(groupId)
      .collection('settlements')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Settlement.fromMap(d.id, groupId, _dates(d.data()))).toList());

  @override
  Future<String> createGroup({
    required String name,
    required String yourName,
    required List<String> otherNames,
  }) async {
    final ref = _groups.doc();
    final group = Group(
      id: ref.id,
      name: name,
      members: [
        Member(id: newId(), name: yourName, uid: currentUid),
        for (final n in otherNames) Member(id: newId(), name: n),
      ],
      accessUids: [currentUid],
      createdAt: DateTime.now(),
    );
    // Not awaited: with offline persistence the write completes locally at
    // once and syncs later, so the UI shouldn't block on the network.
    ref.set(group.toMap());
    return ref.id;
  }

  @override
  Future<void> joinGroup(String groupId) => _groups.doc(groupId).update({
    'accessUids': FieldValue.arrayUnion([currentUid]),
  });

  @override
  Future<void> saveMembers(String groupId, List<Member> members) async {
    _groups.doc(groupId).update({'members': members.map((m) => m.toMap()).toList()});
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    _groups.doc(expense.groupId).collection('expenses').doc(expense.id).set(expense.toMap());
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    _groups.doc(groupId).collection('expenses').doc(expenseId).delete();
  }

  @override
  Future<void> addSettlement(Settlement settlement) async {
    _groups
        .doc(settlement.groupId)
        .collection('settlements')
        .doc(settlement.id)
        .set(settlement.toMap());
  }
}
