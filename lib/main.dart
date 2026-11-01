import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_service.dart';
import 'auth/demo_auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'data/firestore_repository.dart';
import 'data/in_memory_repository.dart';
import 'data/repository.dart';
import 'firebase_options.dart';
import 'state/providers.dart';
import 'ui/auth_gate.dart';

/// `flutter run` uses in-memory demo mode.
/// `flutter run --dart-define=USE_FIREBASE=true` uses Firebase.
const useFirebase = bool.fromEnvironment('USE_FIREBASE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthService authService;
  final Repository Function(String uid) repositoryFactory;
  if (useFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    authService = FirebaseAuthService();
    repositoryFactory = FirestoreRepository.new;
  } else {
    authService = DemoAuthService();
    repositoryFactory = demoRepositories();
  }

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
        repositoryFactoryProvider.overrideWithValue(repositoryFactory),
      ],
      child: const FairSplitApp(),
    ),
  );
}

/// One in-memory repository per uid, kept for the life of the app.
Repository Function(String uid) demoRepositories() {
  final repos = <String, Repository>{};
  return (uid) => repos.putIfAbsent(uid, () => InMemoryRepository(uid));
}

class FairSplitApp extends StatelessWidget {
  const FairSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1B998B);
    return MaterialApp(
      title: 'FairSplit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}
