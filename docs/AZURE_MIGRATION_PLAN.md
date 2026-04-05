# Azure Migration Plan

## Goal

Migrate SwiftCart away from Firebase and move to an Azure-based backend with:

- Azure Database for MySQL Flexible Server
- ASP.NET Core Web API
- JWT authentication
- Flutter app calling the API instead of Firebase directly

## What To Install On Windows

### Required

1. Flutter SDK
2. Android Studio
3. .NET SDK 10 LTS
4. Azure CLI
5. Git

### Recommended

1. Visual Studio 2022 or VS Code
2. MySQL Workbench
3. Postman or Bruno

## Target Architecture

```text
Flutter App
    ->
ASP.NET Core Web API
    ->
Azure Database for MySQL Flexible Server
```

### Auth Direction

- Remove Firebase Auth
- Use API-based login
- API returns JWT access tokens
- Flutter stores token locally and sends it on each authenticated request

## Current Firebase Usage In This Project

Firebase is currently used in:

- `lib/providers/admin_provider.dart`
- `lib/providers/mall_manager_provider.dart`
- `lib/providers/user_auth_provider.dart`
- multiple screens that call `FirebaseFirestore.instance` directly
- `lib/main.dart`
- `lib/firebase_options.dart`

This means the migration must replace both:

1. Firestore data access
2. Firebase authentication

## Migration Strategy

Do this in phases. Do not remove Firebase first.

### Phase 0: Prepare

- document current Firestore collections and flows
- define MySQL schema
- decide API endpoints
- add a repository layer in Flutter so providers stop depending on Firebase classes directly

### Phase 1: Build Backend

- create ASP.NET Core Web API project
- configure MySQL connection
- add authentication endpoints
- add mall, manager, admin, user, product, payment, and announcement endpoints

### Phase 2: Migrate Flutter Data Access

- replace direct Firestore calls with repositories/services
- first migrate admin flows
- then migrate mall manager flows
- then migrate user flows

### Phase 3: Migrate Authentication

- replace Firebase Auth login and signup
- add JWT token storage and refresh strategy
- protect API endpoints by role

### Phase 4: Data Migration

- export Firestore data
- transform subcollections into relational tables
- import into MySQL
- validate counts and key relationships

### Phase 5: Firebase Removal

- remove Firebase packages from `pubspec.yaml`
- remove `firebase_options.dart`
- remove Firebase initialization from `lib/main.dart`
- remove Firebase config files from platform folders

## Proposed First Backend Entities

- `admins`
- `malls`
- `mall_subscriptions`
- `managers`
- `users`
- `products`
- `barcodes`
- `announcements`
- `support_requests`
- `payments`
- `bills`
- `promotions`
- `staff_activity`
- `otp_codes`

## First Flutter Refactor Target

Start with admin flows because they are smaller and better bounded than the full customer flow:

- admin login
- list malls
- add mall
- update mall subscription
- manager account operations
- announcements

## Immediate Next Step

Create the backend project structure in a new `backend/` folder and scaffold:

- ASP.NET Core Web API
- configuration for Azure MySQL
- JWT auth setup
- initial admin and mall endpoints

