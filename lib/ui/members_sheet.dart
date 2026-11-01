import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/upi.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../state/providers.dart';

void showMembersSheet(BuildContext context, Group group) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MembersSheet(groupId: group.id),
  );
}

class _MembersSheet extends ConsumerWidget {
  const _MembersSheet({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final group = ref.watch(groupProvider(groupId)).value;
    if (group == null) return const SizedBox(height: 200);
    final claimed = group.memberForUid(repo.currentUid) != null;

    Future<void> save(List<Member> members) => repo.saveMembers(group.id, members);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('Members', style: Theme.of(context).textTheme.titleLarge)),
          for (final m in group.members)
            ListTile(
              title: Text(m.uid == repo.currentUid ? '${m.name} (you)' : m.name),
              subtitle: Text(m.upiId ?? 'No UPI ID'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!claimed && m.uid == null)
                    TextButton(
                      onPressed: () => save([
                        for (final x in group.members)
                          x.id == m.id ? x.copyWith(uid: repo.currentUid) : x,
                      ]),
                      child: const Text("That's me"),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final edited = await _editMember(context, m);
                      if (edited != null) {
                        await save([for (final x in group.members) x.id == m.id ? edited : x]);
                      }
                    },
                  ),
                ],
              ),
            ),
          ListTile(
            leading: const Icon(Icons.person_add_alt),
            title: const Text('Add member'),
            onTap: () async {
              final added = await _editMember(context, Member(id: repo.newId(), name: ''));
              if (added != null) await save([...group.members, added]);
            },
          ),
        ],
      ),
    );
  }
}

Future<Member?> _editMember(BuildContext context, Member member) {
  final name = TextEditingController(text: member.name);
  final upi = TextEditingController(text: member.upiId ?? '');
  final formKey = GlobalKey<FormState>();
  return showDialog<Member>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(member.name.isEmpty ? 'Add member' : 'Edit member'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            TextFormField(
              controller: upi,
              decoration: const InputDecoration(
                labelText: 'UPI ID (optional)',
                hintText: 'name@okicici',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty || isValidUpiId(v!) ? null : 'Not a valid UPI ID',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              Member(
                id: member.id,
                name: name.text.trim(),
                uid: member.uid,
                upiId: upi.text.trim().isEmpty ? null : upi.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
