# SwiftCart API

## Run Locally

1. Update `appsettings.Development.json`
2. Make sure MySQL is running
3. Run:

```powershell
& "C:\Program Files\dotnet\dotnet.exe" run --project backend/SwiftCart.Api/SwiftCart.Api.csproj
```

## First Endpoints

- `GET /api/health`
- `POST /api/auth/admin/login`

## Notes

- The current admin login flow uses SHA-256 to match the existing Flutter/Firebase logic.
- This is a migration starter, not the final security model.
