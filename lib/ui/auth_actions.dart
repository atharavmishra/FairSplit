import 'package:flutter/material.dart';

import '../auth/auth_service.dart';

/// Runs an auth action, showing failures in a snackbar. Returns whether it
/// succeeded. Closing the Google picker counts as a quiet failure.
Future<bool> runAuthAction(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    return true;
  } on AuthCancelled {
    return false;
  } on AuthException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    return false;
  }
}

/// The "G" mark for Google buttons, drawn without an image asset.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4285F4)),
  );
}
