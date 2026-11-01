# FairSplit

A free, no-limits expense splitter (Splitwise alternative). Flutter + Firebase.

## Run it now (demo mode, no setup)

```bash
flutter run
```

Demo mode keeps data in memory, so it's lost when the app restarts. Good for trying the UI.

## Connect Firebase (real, synced data)

1. Create a project at https://console.firebase.google.com (Spark/free plan).
2. **Build → Authentication → Sign-in method:** enable **Anonymous**.
3. **Build → Firestore Database:** create a database (production mode, region `asia-south1` for India).
4. Install the CLIs and generate `lib/firebase_options.dart`:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --platforms=android,ios --android-package-name=in.fairsplit.app
   ```
5. Deploy the security rules: `firebase deploy --only firestore:rules`
   (run `firebase init firestore` first and point it at the existing `firestore.rules`).
6. Run with Firebase:
   ```bash
   flutter run --dart-define=USE_FIREBASE=true
   ```

## Project layout

```
lib/
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

Before the first upload: create an upload keystore and configure signing in
`android/app/build.gradle.kts` (see https://docs.flutter.dev/deployment/android), and confirm
the `applicationId` (`in.fairsplit.app`). It can't be changed after the first upload.

## Roadmap

- [x] Groups, members without accounts, invite code + claim your name
- [x] Equal / exact / percentage / shares splits, edit & delete
- [x] Live balances, simplify debts, settle up, UPI pay links
- [x] Offline-first (Firestore cache)
- [ ] Google / phone sign-in (link to the anonymous account)
- [ ] Multiple payers in the UI (model already supports it)
- [ ] Receipt scanning (ML Kit), categories, charts, search, CSV export
- [ ] Push reminders, recurring expenses, multi-currency
- [ ] Account deletion screen (required by Play Store), privacy policy page
