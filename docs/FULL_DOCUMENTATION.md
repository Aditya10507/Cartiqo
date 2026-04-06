# Full Project Documentation

## 1. Overview

Cartiqo / SwiftCart is a Flutter retail platform that supports:

- customer shopping and checkout
- mall manager inventory and sales operations
- admin-level mall and manager control

The current architecture is Azure-based and no longer depends on Firebase at runtime.

## 2. Architecture

### Frontend

- Flutter
- Provider
- service-layer API calls through `lib/services`

### Backend

- ASP.NET Core Web API
- Entity Framework Core
- MySQL

### Hosting

- Azure App Service
- Azure Database for MySQL Flexible Server
- Azure Storage Static Website Hosting

## 3. User Roles

### Customer

- email OTP-based signup
- username/password sign in
- forgot-password reset with email OTP
- mall selection
- product search and barcode lookup
- checkout and history

### Mall Manager

- manager login
- product CRUD
- billing settings
- promotions
- staff activity
- payment history

### Admin

- admin login
- malls CRUD
- manager account administration
- announcements
- support request tracking
- payment overview

## 4. Backend Data Domains

The main MySQL domains are:

- admins
- malls
- mall managers
- users
- user signup OTPs
- user password reset OTPs
- products
- barcodes
- bills
- payments
- announcements
- support requests
- promotions
- staff activity

## 5. Backend API

### System

- `GET /api/health`

### Admin API

- `POST /api/auth/admin/login`
- `GET /api/malls`
- `GET /api/malls/{mallId}`
- `POST /api/malls`
- `PUT /api/malls/{mallId}`
- `POST /api/malls/{mallId}/deactivate`
- `PUT /api/malls/{mallId}/billing-settings`
- `GET /api/malls/{mallId}/managers`
- `GET /api/malls/{mallId}/managers/count`
- `POST /api/malls/{mallId}/managers`
- `POST /api/malls/{mallId}/managers/{managerId}/reset-password`
- `POST /api/malls/{mallId}/managers/{managerId}/unlink`
- `POST /api/malls/{mallId}/managers/{managerId}/active`
- `GET /api/announcements`
- `POST /api/announcements`
- `GET /api/supportrequests`
- `POST /api/supportrequests`
- `POST /api/supportrequests/{requestId}/status`
- `GET /api/payments/recent`

### Mall Manager API

- `POST /api/auth/mall-manager/login`
- `GET /api/mall-manager/profile`
- `PUT /api/mall-manager/profile`
- `GET /api/mall-manager/promotions`
- `POST /api/mall-manager/promotions`
- `DELETE /api/mall-manager/promotions/{promotionId}`
- `GET /api/mall-manager/staff-activity`
- `GET /api/payments/malls/{mallId}`
- `GET /api/malls/{mallId}/products`
- `GET /api/malls/{mallId}/products/barcode/{barcode}`
- `POST /api/malls/{mallId}/products`
- `PUT /api/malls/{mallId}/products/{productId}`
- `DELETE /api/malls/{mallId}/products/{productId}`

### Customer/Public API

- `POST /api/auth/users/register/request-otp`
- `POST /api/auth/users/register/verify-otp`
- `POST /api/auth/users/login`
- `POST /api/auth/users/password/request-otp`
- `POST /api/auth/users/password/reset`
- `GET /api/public/malls/{mallId}/products`
- `GET /api/public/malls/{mallId}/products/barcode/{barcode}`
- `GET /api/public/malls/{mallId}/billing-settings`
- `POST /api/public/malls/{mallId}/checkout`
- `GET /api/public/users/{uid}`
- `PUT /api/public/users/{uid}`
- `GET /api/public/users/{uid}/bills`
- `GET /api/public/users/{uid}/payments`

## 6. Flutter Integration Pattern

The Flutter app follows this pattern:

1. screen calls provider
2. provider calls service
3. service calls backend API
4. backend returns DTO/data
5. provider updates app state
6. UI rebuilds

## 7. Main Frontend Modules

### Admin

- [admin_provider.dart](/c:/Users/GS/swiftcart_app/lib/providers/admin_provider.dart)
- admin dashboard screens

### Mall Manager

- [mall_manager_provider.dart](/c:/Users/GS/swiftcart_app/lib/providers/mall_manager_provider.dart)
- product and operations screens

### Customer

- [user_auth_provider.dart](/c:/Users/GS/swiftcart_app/lib/providers/user_auth_provider.dart)
- checkout, search, scan, and profile screens

## 8. Build And Run

### Local backend

```powershell
.\tools\run_backend_local.ps1 -ConnectionString "Server=localhost;Port=3306;Database=swiftcart_dev;User=root;Password=YOUR_PASSWORD;"
```

### Local Flutter app

```powershell
flutter run --dart-define=SWIFTCART_API_BASE_URL=http://localhost:5187
```

### Production web build

```powershell
flutter build web --release --dart-define=SWIFTCART_API_BASE_URL=https://YOUR_API_HOST
```

## 9. Deployment Summary

Production deployment uses Azure:

- API -> Azure App Service
- Database -> Azure Database for MySQL Flexible Server
- Website -> Azure Storage Static Website Hosting

## 10. Notes

- Firebase runtime integration has been removed from the app
- local secrets and environment-specific files should stay out of git
- the backend supports both local and Azure-hosted operation through configuration

