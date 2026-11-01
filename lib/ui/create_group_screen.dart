import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'group_screen.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _name = TextEditingController();
  late final _yourName = TextEditingController(
    text: ref.read(authStateProvider).value?.displayName ?? '',
  );
  final _memberName = TextEditingController();
  final _others = <String>[];

  bool get _valid => _name.text.trim().isNotEmpty && _yourName.text.trim().isNotEmpty;

  void _addMember() {
    final n = _memberName.text.trim();
    if (n.isEmpty) return;
    setState(() {
      _others.add(n);
      _memberName.clear();
    });
  }

  Future<void> _create() async {
    _addMember();
    final id = await ref
        .read(repositoryProvider)
        .createGroup(name: _name.text.trim(), yourName: _yourName.text.trim(), otherNames: _others);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GroupScreen(groupId: id)));
  }

  @override
  void dispose() {
    _name.dispose();
    _yourName.dispose();
    _memberName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Group name', hintText: 'Goa trip'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _yourName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Your name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text('Members', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in _others)
                InputChip(label: Text(n), onDeleted: () => setState(() => _others.remove(n))),
            ],
          ),
          TextField(
            controller: _memberName,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Add a member',
              suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _addMember),
            ),
            onSubmitted: (_) => _addMember(),
          ),
          const SizedBox(height: 8),
          const Text('Friends can join later with the invite code and claim their name.'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _valid ? _create : null,
            child: const Text('Create group'),
          ),
        ),
      ),
    );
  }
}
