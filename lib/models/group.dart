import 'member.dart';

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.members,
    required this.accessUids,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<Member> members;

  /// Signed-in users allowed to read/write this group (see firestore.rules).
  final List<String> accessUids;
  final DateTime createdAt;

  Member? memberById(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Member? memberForUid(String uid) {
    for (final m in members) {
      if (m.uid == uid) return m;
    }
    return null;
  }

  String nameOf(String memberId) => memberById(memberId)?.name ?? 'Someone';

  Group copyWith({String? name, List<Member>? members, List<String>? accessUids}) => Group(
    id: id,
    name: name ?? this.name,
    members: members ?? this.members,
    accessUids: accessUids ?? this.accessUids,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'members': members.map((m) => m.toMap()).toList(),
    'accessUids': accessUids,
    'createdAt': createdAt,
  };

  factory Group.fromMap(String id, Map<String, dynamic> m) => Group(
    id: id,
    name: m['name'] as String,
    members: (m['members'] as List)
        .map((e) => Member.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    accessUids: List<String>.from(m['accessUids'] as List),
    createdAt: m['createdAt'] as DateTime,
  );
}
