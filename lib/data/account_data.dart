import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member.dart';

/// Firestore operations on everything a user has access to, used when
/// switching accounts and when deleting an account.
class AccountData {
  AccountData(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _groups => _db.collection('groups');

  Future<List<String>> groupIdsFor(String uid) async {
    final snap = await _groups.where('accessUids', arrayContains: uid).get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// Gives [to] access to [groupIds] in place of [from], and moves any
  /// member claimed by [from] over to [to].
  Future<void> moveGroups(List<String> groupIds, {required String from, required String to}) async {
    for (final id in groupIds) {
      final ref = _groups.doc(id);
      // Allowed for anyone with the group id (the invite rule).
      await ref.update({
        'accessUids': FieldValue.arrayUnion([to]),
      });
      final members = await _members(ref);
      final alreadyClaimed = members.any((m) => m.uid == to);
      await ref.update({
        'accessUids': FieldValue.arrayRemove([from]),
        'members': [
          for (final m in members)
            if (m.uid != from)
              m.toMap()
            else if (alreadyClaimed)
              _unclaimed(m).toMap()
            else
              m.copyWith(uid: to).toMap(),
        ],
      });
    }
  }

  /// Leaves every group. Groups nobody else has access to are deleted with
  /// their expenses; in shared groups the member stays (by name) so other
  /// people's balances don't change.
  Future<void> deleteUserData(String uid) async {
    final snap = await _groups.where('accessUids', arrayContains: uid).get();
    for (final doc in snap.docs) {
      final access = List<String>.from(doc.data()['accessUids'] as List);
      if (access.length <= 1) {
        for (final sub in ['expenses', 'settlements']) {
          final children = await doc.reference.collection(sub).get();
          await Future.wait(children.docs.map((d) => d.reference.delete()));
        }
        await doc.reference.delete();
      } else {
        final members = await _members(doc.reference);
        await doc.reference.update({
          'accessUids': FieldValue.arrayRemove([uid]),
          'members': [for (final m in members) (m.uid == uid ? _unclaimed(m) : m).toMap()],
        });
      }
    }
  }

  static Future<List<Member>> _members(DocumentReference<Map<String, dynamic>> ref) async {
    final data = (await ref.get()).data()!;
    return (data['members'] as List)
        .map((e) => Member.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Member _unclaimed(Member m) => Member(id: m.id, name: m.name, upiId: m.upiId);
}
