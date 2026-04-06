# Tools And Tech Stack

## Frontend

- Flutter
- Dart
- Provider for state management
- `http` package for API integration
- `shared_preferences` for user session persistence
- `mobile_scanner` for barcode and QR scanning
- `printing`, `pdf`, `csv`, and file/image picker utilities

## Backend

- ASP.NET Core Web API
- C#
- Entity Framework Core
- Pomelo MySQL provider
- JWT-based authentication for API sessions

## Database

- MySQL
- Azure Database for MySQL Flexible Server in production
- local MySQL for development

## Cloud And Hosting

- Azure App Service for backend hosting
- Azure Storage Static Website Hosting for Flutter web build
- Azure CLI for provisioning and deployment

## Local Tooling

- Flutter SDK
- .NET SDK
- MySQL Server / MySQL Workbench
- Git
- PowerShell

## Development Style

- Flutter app talks to backend APIs through service classes in `lib/services`
- providers coordinate UI state and API calls
- backend controllers expose domain-specific REST endpoints
- backend entities and migrations define the MySQL schema

