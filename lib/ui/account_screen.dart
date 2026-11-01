import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'auth_actions.dart';
import 'auth_gate.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {bool leaves = false}) async {
    setState(() => _busy = true);
    final ok = await runAuthAction(context, action);
    if (!mounted) return;
    setState(() => _busy = false);
    // Replace the whole stack rather than popping: resuming the paused home
    // route after the user changed trips Riverpod's rebuild-during-build check.
    if (ok && leaves) {
      Navigator.of(
        context,
      ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthGate()), (_) => false);
    }
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    if (user == null) return const Scaffold();
    final name = user.displayName ?? (user.isAnonymous ? 'Guest' : 'You');

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          children: [
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 40,
                foregroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(name, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            Text(
              user.email ?? 'Guest account on this phone',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (user.isAnonymous)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Keep your groups safe', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Guest data is lost if you sign out or uninstall. Link Google '
                        'to keep it and use it on other phones.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const GoogleMark(),
                        label: const Text('Link Google account'),
                        onPressed: () => _run(auth.signInWithGoogle),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                if (user.isAnonymous &&
                    !await _confirm(
                      'Sign out of guest account?',
                      'You will lose access to your groups on this phone unless you '
                          'link Google first.',
                      'Sign out',
                    )) {
                  return;
                }
                await _run(auth.signOut, leaves: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
              title: Text('Delete account', style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('Removes you and your data permanently'),
              onTap: () async {
                if (!await _confirm(
                  'Delete account?',
                  'You will be removed from all groups. Groups only you use are deleted '
                      'with their expenses. In shared groups your name and past expenses '
                      'stay so everyone else\'s balances remain correct. This cannot be undone.',
                  'Delete',
                )) {
                  return;
                }
                await _run(auth.deleteAccount, leaves: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
