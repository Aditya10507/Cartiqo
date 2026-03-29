# Deployment and Operations

_Generated on 2026-03-25._

## Web Hosting (Firebase Hosting)

Build + deploy steps:

```powershell
cd C:\Users\GS\swiftcart_app
flutter pub get
flutter build web --release
firebase deploy --only hosting
```

## Cloud Functions (Firebase Functions)

Local build steps:

```powershell
cd C:\Users\GS\swiftcart_app\functions
npm ci
npm run build
firebase deploy --only functions
```

### Important: Billing Plan Requirement

Deploying Cloud Functions can require enabling Google APIs (Cloud Build, Artifact Registry). If your Firebase project is on the free plan, deploy may be blocked until upgraded to Blaze.

## Required Secrets/Environment Variables (Functions)

- TWILIO_ACCOUNT_SID
- TWILIO_AUTH_TOKEN
- TWILIO_PHONE_NUMBER
- RESEND_API_KEY (if using Resend email flow)
- FROM_EMAIL (optional override)

