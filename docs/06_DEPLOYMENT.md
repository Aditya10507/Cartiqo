# Deployment

## Production Hosting

Production uses Azure:

- Azure App Service for the backend API
- Azure Database for MySQL Flexible Server for the database
- Azure Storage Static Website Hosting for the Flutter web build

## Local Development

### Backend

1. Install .NET SDK
2. Install MySQL locally
3. Update `backend/SwiftCart.Api/appsettings.Development.json`
4. Run:

```powershell
.\tools\run_backend_local.ps1 -ConnectionString "Server=localhost;Port=3306;Database=swiftcart_dev;User=root;Password=YOUR_PASSWORD;"
```

### Flutter

```powershell
flutter pub get
flutter run --dart-define=SWIFTCART_API_BASE_URL=http://localhost:5187
```

For physical-device testing, use your machine IP instead of `localhost`.

## Backend Deployment Notes

- publish the API with `dotnet publish`
- deploy the publish artifact to Azure App Service
- set production app settings in Azure
- point the API at the Azure MySQL connection string

## Web Deployment Notes

- build the Flutter web app with the production API URL
- upload the generated `build/web` files to Azure Storage Static Website Hosting

## Important Secret Handling

Do not commit:

- local MySQL passwords
- Azure environment export files
- JWT production secrets
- SMTP app passwords
- service account files

