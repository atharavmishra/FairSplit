import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/account_data.dart';
import 'auth_service.dart';

/// Optional: the OAuth "Web client" ID from Firebase. Normally read from
/// google-services.json; pass --dart-define=GOOGLE_SERVER_CLIENT_ID=... if
/// sign-in fails with a missing client ID.
const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _data = AccountData(db ?? FirebaseFirestore.instance);

  final FirebaseAuth _auth;
  final AccountData _data;
  Future<void>? _googleInit;

  @override
  bool get supportsGoogle => true;

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_toAppUser);

  static AppUser? _toAppUser(User? u) {
    if (u == null) return null;
    final google = u.providerData.where((p) => p.providerId == 'google.com').firstOrNull;
    return AppUser(
      uid: u.uid,
      isAnonymous: u.isAnonymous,
      displayName: u.displayName ?? google?.displayName,
      email: u.email ?? google?.email,
      photoUrl: u.photoURL ?? google?.photoURL,
    );
  }

  @override
  Future<void> continueAsGuest() => _guard(_auth.signInAnonymously);

  /// Shows the Google account picker and returns a Firebase credential.
  Future<(OAuthCredential, GoogleSignInAccount)> _googleCredential() async {
    _googleInit ??= GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    await _googleInit;
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google returned no ID token. Check the SHA-1 setup in README.');
      }
      return (GoogleAuthProvider.credential(idToken: idToken), account);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw const AuthCancelled();
      throw AuthException('Google sign-in failed: ${e.description ?? e.code.name}');
    }
  }

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final (credential, account) = await _googleCredential();
    final current = _auth.currentUser;
    if (current == null) {
      await _auth.signInWithCredential(credential);
      return;
    }
    if (!current.isAnonymous) return;

    try {
      // Same uid afterwards, so all the guest's groups carry over as is.
      await current.linkWithCredential(credential);
      if (current.displayName == null && account.displayName != null) {
        await current.updateDisplayName(account.displayName);
      }
      await current.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use') rethrow;
      // This Google account already has a FairSplit account: switch to
      // it and bring the guest's groups along. Group ids must be read
      // while still signed in as the guest.
      final guestUid = current.uid;
      final groupIds = await _data.groupIdsFor(guestUid);
      final result = await _auth.signInWithCredential(e.credential ?? credential);
      await _data.moveGroups(groupIds, from: guestUid, to: result.user!.uid);
    }
  });

  @override
  Future<void> signOut() => _guard(() async {
    if (_googleInit != null) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  });

  @override
  Future<void> deleteAccount() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _data.deleteUserData(user.uid);
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login' || user.isAnonymous) rethrow;
      final (credential, _) = await _googleCredential();
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    }
    if (_googleInit != null) await GoogleSignIn.instance.disconnect();
  });

  /// Turns Firebase errors into messages fit for a snackbar.
  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(switch (e.code) {
        'network-request-failed' => 'No internet connection',
        'operation-not-allowed' => 'This sign-in method is not enabled in Firebase',
        'user-disabled' => 'This account has been disabled',
        _ => e.message ?? 'Sign-in failed (${e.code})',
      });
    }
  }
}
