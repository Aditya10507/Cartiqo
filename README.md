# Cartiqo / SwiftCart

Cartiqo is a Flutter-based retail checkout and mall operations platform with:

- a customer-facing shopping and billing experience
- an admin dashboard for mall and manager administration
- a mall-manager dashboard for products, promotions, billing settings, and sales activity

## Current Architecture

- Frontend: Flutter (Provider state management)
- Backend: Firebase Auth & Cloud Firestore
- Logic: Firebase Cloud Functions
- Hosting: Firebase Hosting

- Customer signup with email OTP verification
- Customer username/password sign in
- Customer forgot-password flow with email OTP
- Mall selection, product search, barcode lookup, and checkout
- Admin login, mall management, manager management, announcements, and support request handling
- Mall manager login, product CRUD, billing settings, promotions, staff activity, and payment history

## Project Structure

- [lib](/c:/Users/GS/swiftcart_app/lib): Flutter app source
- [docs](/c:/Users/GS/swiftcart_app/docs): project documentation
- [tools](/c:/Users/GS/swiftcart_app/tools): local scripts for setup

## Local Development

### Flutter app

```powershell
flutter pub get
flutter run
```

## Documentation

See [docs/INDEX.md](/c:/Users/GS/swiftcart_app/docs/INDEX.md) for the full documentation set.
