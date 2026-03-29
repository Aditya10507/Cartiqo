# Models, Tools, and Technologies

_Generated on 2026-03-25 from the current codebase._

## Core App Stack

- Flutter (Dart) for Android/iOS/Web UI.
- Provider for state management.
- Firebase Core + Cloud Firestore as the primary backend database.
- Firebase Auth for user authentication.
- Firebase Hosting for web deployment.

## Operational/Feature Libraries

- mobile_scanner + vibration: barcode/QR scanning with haptics feedback.
- pdf + printing: generate printable PDFs (labels/receipts) and trigger print dialogs.
- csv + file_picker + web download helper: export operational data (sales dashboard, subscriptions, etc.) as CSV.
- crypto (sha256): hashing for manager/admin credential workflows stored in Firestore (as implemented in providers).
- qr_flutter: QR generation for mall assets and labels.

## Firebase Cloud Functions Stack (functions/)

- Runtime: 20
- TypeScript build pipeline (`npm run build`).
- firebase-admin + firebase-functions.
- Twilio for SMS OTP sending (requires Twilio env vars).
- Resend (HTTP API) for email OTP flows (requires API key).

## Flutter Dependencies (pubspec.yaml)

### Dependencies

```yaml
flutter: (sdk)
cupertino_icons: ^1.0.8
firebase_core: ^4.4.0
cloud_firestore: ^6.1.2
firebase_auth: ^6.1.4
provider: ^6.1.5+1
mobile_scanner: ^7.2.0
vibration: ^2.1.0
image_picker: ^1.1.2
path_provider: ^2.1.5
crypto: ^3.0.3
qr_flutter: ^4.1.0
pdf: ^3.11.3
printing: ^5.14.2
csv: ^6.0.0
file_picker: ^8.0.0
```

### Dev Dependencies

```yaml
flutter_test: (sdk)
flutter_lints: ^6.0.0
```

