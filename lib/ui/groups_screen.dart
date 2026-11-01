import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'create_group_screen.dart';
import 'group_screen.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('FairSplit'),
        actions: [
          IconButton(
            tooltip: 'Join with invite code',
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => _join(context, ref),
          ),
        ],
      ),
      body: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load groups\n$e')),
        data: (list) => list.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final g = list[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(g.name.characters.first.toUpperCase())),
                    title: Text(g.name),
                    subtitle: Text(g.members.map((m) => m.name).join(', '),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => GroupScreen(groupId: g.id))),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New group'),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
      ),
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Invite code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Join')),
        ],
      ),
    );
    if (code == null || code.isEmpty || !context.mounted) return;
    try {
      await ref.read(repositoryProvider).joinGroup(code);
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => GroupScreen(groupId: code)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not join. Check the code.')));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('No groups yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Create a group for a trip, your flat, or office lunches.',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
