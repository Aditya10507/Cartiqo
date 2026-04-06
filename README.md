# Cartiqo / SwiftCart

Cartiqo is a Flutter-based retail checkout and mall operations platform with:

- a customer-facing shopping and billing experience
- an admin dashboard for mall and manager administration
- a mall-manager dashboard for products, promotions, billing settings, and sales activity
- an ASP.NET Core Web API backend
- a MySQL data layer hosted on Azure

The project was migrated from the earlier Firebase/Firestore architecture to an Azure-hosted stack.

## Current Architecture

- Frontend: Flutter
- State management: Provider
- Backend API: ASP.NET Core Web API
- ORM: Entity Framework Core + Pomelo MySQL provider
- Database: MySQL
- Cloud hosting:
  - Azure App Service for the API
  - Azure Database for MySQL Flexible Server
  - Azure Storage Static Website Hosting for the web build

## Main Features

- Customer signup with email OTP verification
- Customer username/password sign in
- Customer forgot-password flow with email OTP
- Mall selection, product search, barcode lookup, and checkout
- Admin login, mall management, manager management, announcements, and support request handling
- Mall manager login, product CRUD, billing settings, promotions, staff activity, and payment history

## Project Structure

- [backend](/c:/Users/GS/swiftcart_app/backend): ASP.NET Core backend
- [lib](/c:/Users/GS/swiftcart_app/lib): Flutter app source
- [docs](/c:/Users/GS/swiftcart_app/docs): project documentation
- [tools](/c:/Users/GS/swiftcart_app/tools): local scripts for setup and Azure utilities

## Local Development

### Flutter app

```powershell
flutter pub get
flutter run --dart-define=SWIFTCART_API_BASE_URL=http://localhost:5187
```

### Backend API

```powershell
.\tools\run_backend_local.ps1 -ConnectionString "Server=localhost;Port=3306;Database=swiftcart_dev;User=root;Password=YOUR_PASSWORD;"
```

## Documentation

See [docs/INDEX.md](/c:/Users/GS/swiftcart_app/docs/INDEX.md) for the full documentation set.

