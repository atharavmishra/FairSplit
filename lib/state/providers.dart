import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../core/balances.dart';
import '../data/repository.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../models/settlement.dart';

/// Overridden in main() with the Firebase or demo implementation.
final authServiceProvider = Provider<AuthService>((ref) => throw UnimplementedError());

/// Builds the repository for a signed-in uid. Overridden in main().
final repositoryFactoryProvider = Provider<Repository Function(String uid)>(
  (ref) => throw UnimplementedError(),
);

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authServiceProvider).userChanges(),
);

/// Only valid while signed in; the UI below AuthGate guarantees that.
final repositoryProvider = Provider<Repository>((ref) {
  // Rebuild only when the uid changes, not on every profile update.
  final uid = ref.watch(authStateProvider.select((s) => s.value?.uid));
  if (uid == null) throw StateError('Not signed in');
  return ref.watch(repositoryFactoryProvider)(uid);
});

final groupsProvider = StreamProvider<List<Group>>(
  (ref) => ref.watch(repositoryProvider).watchGroups(),
);

final groupProvider = StreamProvider.family<Group?, String>(
  (ref, id) => ref.watch(repositoryProvider).watchGroup(id),
);

final expensesProvider = StreamProvider.family<List<Expense>, String>(
  (ref, id) => ref.watch(repositoryProvider).watchExpenses(id),
);

final settlementsProvider = StreamProvider.family<List<Settlement>, String>(
  (ref, id) => ref.watch(repositoryProvider).watchSettlements(id),
);

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
