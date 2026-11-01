import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../models/settlement.dart';
import '../state/providers.dart';
import 'add_expense_screen.dart';
import 'members_sheet.dart';
import 'settle_up_sheet.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(groupProvider(groupId))
        .when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('$e')),
          ),
          data: (group) => group == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: const Center(child: Text('Group not found')),
                )
              : _GroupView(group: group),
        );
  }
}

class _GroupView extends ConsumerWidget {
  const _GroupView({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = group.memberForUid(ref.watch(repositoryProvider).currentUid);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            IconButton(
              tooltip: 'Members',
              icon: const Icon(Icons.people_outline),
              onPressed: () => showMembersSheet(context, group),
            ),
            IconButton(
              tooltip: 'Invite',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _showInvite(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (me == null)
              MaterialBanner(
                content: const Text('Which member are you? Claim your name to see your share.'),
                actions: [
                  TextButton(
                    onPressed: () => showMembersSheet(context, group),
                    child: const Text('Choose'),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _ExpensesTab(group: group, myId: me?.id),
                  _BalancesTab(group: group, myId: me?.id),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddExpenseScreen(group: group)),
          ),
        ),
      ),
    );
  }

  void _showInvite(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite to group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this code. Friends tap "Join" on the home screen and paste it.'),
            const SizedBox(height: 12),
            SelectableText(group.id, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: group.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Invite code copied')));
            },
            child: const Text('Copy code'),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.group, required this.myId});

  final Group group;
  final String? myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider(group.id));
    final settlements = ref.watch(settlementsProvider(group.id));
    return expenses.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (expenseList) {
        // Expenses and settlements in one feed, newest first.
        final items = <Object>[...expenseList, ...settlements.value ?? const <Settlement>[]]
          ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
        if (items.isEmpty) {
          return const Center(child: Text('No expenses yet. Tap "Add expense".'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: items.length,
          itemBuilder: (context, i) => switch (items[i]) {
            final Expense e => _ExpenseTile(group: group, expense: e, myId: myId),
            final Settlement s => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
              title: Text('${group.nameOf(s.from)} paid ${group.nameOf(s.to)}'),
              subtitle: Text(DateFormat('d MMM').format(s.date)),
              trailing: Text(formatAmount(s.amount)),
            ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  static DateTime _dateOf(Object o) => o is Expense ? o.date : (o as Settlement).date;
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.group, required this.expense, required this.myId});

  final Group group;
  final Expense expense;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final payers = expense.paidBy.keys.map(group.nameOf).join(', ');
    Widget? trailing;
    if (myId != null) {
      final mine = (expense.paidBy[myId] ?? 0) - (expense.owed[myId] ?? 0);
      trailing = mine == 0
          ? const Text('not involved')
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mine > 0 ? 'you lent' : 'you owe',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  formatAmount(mine.abs()),
                  style: TextStyle(color: mine > 0 ? colors.primary : colors.error),
                ),
              ],
            );
    }
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          DateFormat('d\nMMM').format(expense.date),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ),
      title: Text(expense.description),
      subtitle: Text('$payers paid ${formatAmount(expense.amount)}'),
      trailing: trailing,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(group: group, existing: expense),
        ),
      ),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  const _BalancesTab({required this.group, required this.myId});

  final Group group;
  final String? myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return ref
        .watch(balancesProvider(group.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (b) => ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final m in group.members)
                ListTile(
                  leading: CircleAvatar(child: Text(m.name.characters.first.toUpperCase())),
                  title: Text(m.id == myId ? '${m.name} (you)' : m.name),
                  trailing: switch (b.net[m.id] ?? 0) {
                    0 => const Text('settled up'),
                    final v when v > 0 => Text(
                      'gets back ${formatAmount(v)}',
                      style: TextStyle(color: colors.primary),
                    ),
                    final v => Text(
                      'owes ${formatAmount(-v)}',
                      style: TextStyle(color: colors.error),
                    ),
                  },
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('Suggested payments', style: Theme.of(context).textTheme.titleMedium),
              ),
              if (b.transfers.isEmpty) const ListTile(title: Text('Everyone is settled up 🎉')),
              for (final t in b.transfers)
                ListTile(
                  title: Text('${group.nameOf(t.from)} pays ${group.nameOf(t.to)}'),
                  subtitle: Text(formatAmount(t.amount)),
                  trailing: FilledButton.tonal(
                    onPressed: () => showSettleUpSheet(context, group, t),
                    child: const Text('Settle'),
                  ),
                ),
            ],
          ),
        );
  }
}
