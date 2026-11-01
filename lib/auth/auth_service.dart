class AppUser {
  const AppUser({
    required this.uid,
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;

  /// Guest account: data is tied to this install until linked to Google.
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoUrl;
}

/// A failure worth showing to the user.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The user closed the Google account picker; not an error.
class AuthCancelled implements Exception {
  const AuthCancelled();
}

abstract class AuthService {
  /// Emits the signed-in user, or null when signed out.
  Stream<AppUser?> userChanges();

  bool get supportsGoogle;

  Future<void> continueAsGuest();

  /// Signs in with Google. If currently a guest, links Google to the guest
  /// account so nothing is lost.
  Future<void> signInWithGoogle();

  Future<void> signOut();

  /// Removes the user from all groups, deletes groups nobody else uses,
  /// then deletes the account itself.
  Future<void> deleteAccount();
}
