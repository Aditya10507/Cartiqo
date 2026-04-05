# Database Setup

## Current Status

The app backend is ready for:

- JWT auth
- admin login endpoint
- mall CRUD endpoints
- EF Core migrations for `admins` and `malls`

Before testing those endpoints, you need a running MySQL server.

## Option 1: Local MySQL

Install one of these:

- MySQL Server
- MySQL Installer for Windows
- MySQL Workbench plus MySQL Server

Then update the connection string in:

- `backend/SwiftCart.Api/appsettings.Development.json`

Or run:

```powershell
.\tools\run_backend_local.ps1 -ConnectionString "Server=localhost;Port=3306;Database=swiftcart_dev;User=root;Password=YOUR_PASSWORD;"
```

That script will:

1. apply EF migrations
2. start the backend API

## Option 2: Azure Database for MySQL

First login:

```powershell
$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
az login
```

Then provision Azure MySQL:

```powershell
.\tools\provision_azure_mysql.ps1 -AdminPassword "YOUR_STRONG_PASSWORD"
```

After provisioning, use the server hostname in the backend connection string.

Example format:

```text
Server=swiftcart-mysql-server.mysql.database.azure.com;Port=3306;Database=swiftcart;User=swiftcartadmin;Password=YOUR_PASSWORD;SslMode=Required;
```

## After Database Is Ready

Run:

```powershell
.\tools\run_backend_local.ps1 -ConnectionString "YOUR_CONNECTION_STRING"
```

Then test:

- `GET http://localhost:5187/api/health`
- `POST http://localhost:5187/api/auth/admin/login`

## Important

In development, create the first admin with:

```powershell
Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:5187/api/setup/bootstrap-admin" `
  -ContentType "application/json" `
  -Body '{"setupKey":"dev-bootstrap-key","name":"Admin","email":"admin@swiftcart.com","password":"admin123","role":"super_admin"}'
```

After that, you can log in through the new backend.
