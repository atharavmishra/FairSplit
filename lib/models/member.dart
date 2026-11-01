/// A person in a group. They don't need an account: [uid] is set only
/// once a signed-in user claims this member as themselves.
class Member {
  const Member({required this.id, required this.name, this.uid, this.upiId});

  final String id;
  final String name;
  final String? uid;
  final String? upiId;

  Member copyWith({String? name, String? uid, String? upiId}) => Member(
        id: id,
        name: name ?? this.name,
        uid: uid ?? this.uid,
        upiId: upiId ?? this.upiId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        if (uid != null) 'uid': uid,
        if (upiId != null && upiId!.isNotEmpty) 'upiId': upiId,
      };

  factory Member.fromMap(Map<String, dynamic> m) => Member(
        id: m['id'] as String,
        name: m['name'] as String,
        uid: m['uid'] as String?,
        upiId: m['upiId'] as String?,
      );
}
