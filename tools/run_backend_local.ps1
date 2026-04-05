param(
    [string]$ConnectionString = "Server=localhost;Port=3306;Database=swiftcart_dev;User=root;Password=CHANGE_ME;",
    [string]$ServerVersion = "8.0.36"
)

$dotnet = "C:\Program Files\dotnet\dotnet.exe"
$project = "backend/SwiftCart.Api/SwiftCart.Api.csproj"

$env:ASPNETCORE_ENVIRONMENT = "Development"
$env:MySql__ConnectionString = $ConnectionString
$env:MySql__ServerVersion = $ServerVersion

Write-Host "Applying EF migrations..."
& $dotnet dotnet-ef database update --project $project --startup-project $project
if ($LASTEXITCODE -ne 0) {
    throw "Database update failed."
}

Write-Host "Starting API on http://0.0.0.0:5187 ..."
& $dotnet run --project $project --launch-profile http
