import 'dart:async';

import 'auth_service.dart';

/// Local-only auth for demo mode and tests. Google is unavailable.
class DemoAuthService implements AuthService {
  DemoAuthService({AppUser? initialUser}) : _user = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  void _set(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  bool get supportsGoogle => false;

  @override
  Stream<AppUser?> userChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> continueAsGuest() async => _set(const AppUser(uid: 'local-user', isAnonymous: true));

  @override
  Future<void> signInWithGoogle() async =>
      throw const AuthException('Google sign-in needs Firebase. See README to set it up.');

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<void> deleteAccount() async => _set(null);
}
