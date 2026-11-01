# FairSplit

A free, no-limits expense splitter (Splitwise alternative). Flutter + Firebase.

**Plan & progress tracker:** https://claude.ai/artifact/4sXMV7ZawABBpvuF6Xq5JK

## Run it now (demo mode, no setup)

```bash
flutter run
```

Demo mode keeps data in memory, so it's lost when the app restarts. Good for trying the UI.
"Continue with Google" needs Firebase; use "Continue as guest" in demo mode.

## Connect Firebase (real, synced data)

1. Create a project at https://console.firebase.google.com (Spark/free plan).
2. **Build → Authentication → Sign-in method:** enable **Anonymous** and **Google**
   (pick your email as the support email).
3. **Build → Firestore Database:** create a database (production mode, region `asia-south1` for India).
4. Install the CLIs and generate `lib/firebase_options.dart`:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --platforms=android,ios --android-package-name=in.fairsplit.app
   ```
5. **Register your SHA-1 for Google sign-in** (Android needs it, or sign-in fails with a
   "developer error"):
   ```bash
   cd android && ./gradlew signingReport
   ```
   Copy the SHA-1 (and SHA-256) of the `debug` variant into **Project settings → Your apps →
   Android app → Add fingerprint**, then re-run `flutterfire configure` so `google-services.json`
   includes the OAuth client. Repeat later for your release/upload key **and** the
   "App signing key" Play Console shows under *Test and release → App integrity*.

   If sign-in still says the client ID is missing, pass the **Web client** ID (Google Cloud
   console → Credentials, "Web client (auto created by Google Service)"):
   `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`.

   iOS only: add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` as a URL scheme in
   `ios/Runner/Info.plist` (see the google_sign_in package README).
6. Deploy the security rules: `firebase deploy --only firestore:rules`
   (run `firebase init firestore` first and point it at the existing `firestore.rules`).
7. Run with Firebase:
   ```bash
   flutter run --dart-define=USE_FIREBASE=true
   ```

## How sign-in works

- **Guest** = Firebase anonymous account. Works offline, no personal data.
- **Link Google** (Account screen) keeps the same user id, so every group carries over.
- If that Google account already used FairSplit on another phone, the app switches to it and
  moves the guest's groups (and claimed member names) into it.
- **Delete account** removes you from every group, deletes groups nobody else uses (with their
  expenses), keeps your name in shared groups so others' balances stay right, then deletes the
  Firebase user (asking Google to re-confirm if the last sign-in was long ago).

## Project layout

```
lib/
  auth/      AuthService: Firebase (guest + Google) and demo implementations
  core/      money (paise), split engine, simplify debts, UPI links   <- pure Dart, unit tested
  models/    Group, Member, Expense, Settlement
  data/      Repository interface + Firestore and in-memory implementations
  state/     Riverpod providers (live balances)
  ui/        screens
firestore.rules   access control: only group members can read/write
```

All money is stored as **integer paise**. Splits always add up exactly; leftover paise go to
the first members in the list.

## Tests

```bash
flutter test
```

## Release build (Play Store)

```bash
flutter build appbundle --dart-define=USE_FIREBASE=true
```

Release builds are signed with the upload key named in `android/key.properties`
(gitignored), in this format:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Without that file, release builds fall back to the debug key, which Play rejects. Keep the
keystore and its passwords backed up somewhere safe: with Play App Signing, a lost upload key
can be reset through Play support, but it takes days. The `applicationId` (`in.fairsplit.app`)
can't be changed after the first upload.

## Privacy policy and account-deletion pages

`docs/` holds the public site Play Store requires: `privacy.html`, `delete-account.html` and a
landing page. Support contact on the pages: atharvmishra77@gmail.com.

1. Publish with GitHub Pages: in https://github.com/atharavmishra/FairSplit go to
   Settings → Pages → Deploy from a branch → `main`, folder `/docs`.
2. The pages then live at https://atharavmishra.github.io/FairSplit/ — this base URL is in
   `lib/core/links.dart` (used by the Account screen). Paste the privacy and deletion URLs into
   Play Console.

## Roadmap

- [x] Groups, members without accounts, invite code + claim your name
- [x] Equal / exact / percentage / shares splits, edit & delete
- [x] Live balances, simplify debts, settle up, UPI pay links
- [x] Offline-first (Firestore cache)
- [x] Google sign-in; guests link Google without losing data (or merge into an existing account)
- [x] In-app account deletion (leaves groups, deletes groups only you used)
- [ ] Multiple payers in the UI (model already supports it)
- [ ] Receipt scanning (ML Kit), categories, charts, search, CSV export
- [ ] Push reminders, recurring expenses, multi-currency
- [x] Privacy policy + account-deletion pages (`docs/`; publishing pending)
- [x] App icon and splash screen
- [ ] Phone (OTP) sign-in
