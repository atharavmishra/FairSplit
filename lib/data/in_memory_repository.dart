import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/settlement.dart';
import 'repository.dart';

/// Demo backend that keeps everything in memory. Data is lost on restart.
class InMemoryRepository implements Repository {
  InMemoryRepository([this.currentUid = 'local-user']);

  final _uuid = const Uuid();
  final _changes = StreamController<void>.broadcast();
  final _groups = <String, Group>{};
  final _expenses = <String, Map<String, Expense>>{};
  final _settlements = <String, List<Settlement>>{};

  @override
  final String currentUid;

  @override
  String newId() => _uuid.v4();

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  void _notify() => _changes.add(null);

  @override
  Stream<List<Group>> watchGroups() =>
      _watch(() => _groups.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Stream<Group?> watchGroup(String groupId) => _watch(() => _groups[groupId]);

  @override
  Stream<List<Expense>> watchExpenses(String groupId) => _watch(
    () => (_expenses[groupId]?.values.toList() ?? [])..sort((a, b) => b.date.compareTo(a.date)),
  );

  @override
  Stream<List<Settlement>> watchSettlements(String groupId) =>
      _watch(() => List.of(_settlements[groupId] ?? const []));

  @override
  Future<String> createGroup({
    required String name,
    required String yourName,
    required List<String> otherNames,
  }) async {
    final id = newId();
    _groups[id] = Group(
      id: id,
      name: name,
      members: [
        Member(id: newId(), name: yourName, uid: currentUid),
        for (final n in otherNames) Member(id: newId(), name: n),
      ],
      accessUids: [currentUid],
      createdAt: DateTime.now(),
    );
    _notify();
    return id;
  }

  @override
  Future<void> joinGroup(String groupId) async {
    if (!_groups.containsKey(groupId)) throw StateError('No group with that code');
  }

  @override
  Future<void> saveMembers(String groupId, List<Member> members) async {
    _groups[groupId] = _groups[groupId]!.copyWith(members: members);
    _notify();
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    (_expenses[expense.groupId] ??= {})[expense.id] = expense;
    _notify();
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    _expenses[groupId]?.remove(expenseId);
    _notify();
  }

  @override
  Future<void> addSettlement(Settlement settlement) async {
    (_settlements[settlement.groupId] ??= []).add(settlement);
    _notify();
  }
}
