# Firebase Migration Plan (Reversion)

## Goal
Decommission the ASP.NET Core + MySQL backend and return to a Firebase-centric architecture.

## Phase 1: Flutter Configuration
- Re-add `firebase_core`, `cloud_firestore`, and `firebase_auth` to `pubspec.yaml`.
- Run `flutterfire configure` to generate `firebase_options.dart`.
- Re-enable Firebase initialization in `lib/main.dart`.

## Phase 2: Authentication
- Replace Azure API calls with direct `FirebaseAuth` calls in the Flutter Providers.
- Migrate "Easy Login" / Demo accounts to Firebase Auth test accounts.
- Use Firebase Cloud Functions for custom Email OTP flows previously handled by the Azure API.

## Phase 3: Data Mapping
Transform the MySQL schema back to Firestore documents:
- **Malls:** `malls` collection.
- **Managers:** `malls/{id}/managers` subcollection.
- **Products/Barcodes:** `malls/{id}/products` and `malls/{id}/barcodes`.
- **Users:** `users` collection.
- **Bills/Payments:** Subcollections under `users/{uid}` and `malls/{mallId}`.

## Phase 4: Provider Refactoring
- Replace `http` API calls in `lib/providers/` with `FirebaseFirestore.instance` and `FirebaseAuth.instance` calls.
- Update models to support `fromFirestore` and `toFirestore` mapping.
- Implement Firestore Security Rules to replace the Azure API authorization logic.

## Phase 5: Data Migration (SQL to Firestore)
- Run `node tools/migrate_sql_to_firebase.js` to transfer Malls, Products, and User Profiles from MySQL to Firestore.

## Phase 6: Decommissioning
- Delete the `backend/` folder once all logic is moved to either Flutter or Cloud Functions.
- Shut down Azure App Service and Azure Database for MySQL.

## Success Criteria
- Flutter app communicates directly with Firestore.
- Authentication is managed via Firebase Auth.
- JWT token services are no longer used.