import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balances.dart';
import '../data/repository.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../models/settlement.dart';

/// Overridden in main() with the Firestore or in-memory implementation.
final repositoryProvider = Provider<Repository>((ref) => throw UnimplementedError());

final groupsProvider =
    StreamProvider<List<Group>>((ref) => ref.watch(repositoryProvider).watchGroups());

final groupProvider = StreamProvider.family<Group?, String>(
    (ref, id) => ref.watch(repositoryProvider).watchGroup(id));

final expensesProvider = StreamProvider.family<List<Expense>, String>(
    (ref, id) => ref.watch(repositoryProvider).watchExpenses(id));

final settlementsProvider = StreamProvider.family<List<Settlement>, String>(
    (ref, id) => ref.watch(repositoryProvider).watchSettlements(id));

class GroupBalances {
  const GroupBalances(this.net, this.transfers);
  final Map<String, int> net;
  final List<Transfer> transfers;
}

/// Net balances and simplified payments for a group, recomputed live.
final balancesProvider = Provider.family<AsyncValue<GroupBalances>, String>((ref, id) {
  final expenses = ref.watch(expensesProvider(id));
  final settlements = ref.watch(settlementsProvider(id));
  return expenses.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (e) => settlements.when(
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
      data: (s) {
        final net = netBalances(e, s);
        return AsyncValue.data(GroupBalances(net, simplifyDebts(net)));
      },
    ),
  );
});
