import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'groups_screen.dart';
import 'sign_in_screen.dart';

/// Shows sign-in until there is a user, then the app.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(authStateProvider)
        .when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const SignInScreen(),
          // Keyed by uid so switching accounts starts from a clean screen.
          data: (user) =>
              user == null ? const SignInScreen() : GroupsScreen(key: ValueKey(user.uid)),
        );
  }
}
