param(
    [string]$ResourceGroup = "swiftcart-rg",
    [string]$Location = "centralindia",
    [string]$ServerName = "swiftcart-mysql-server",
    [string]$AdminUser = "swiftcartadmin",
    [string]$AdminPassword = "CHANGE_THIS_PASSWORD",
    [string]$DatabaseName = "swiftcart"
)

$azPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
$env:Path += ";$azPath"

Write-Host "Creating resource group..."
az group create --name $ResourceGroup --location $Location
if ($LASTEXITCODE -ne 0) {
    throw "Resource group creation failed."
}

Write-Host "Creating Azure Database for MySQL Flexible Server..."
az mysql flexible-server create `
    --resource-group $ResourceGroup `
    --name $ServerName `
    --location $Location `
    --admin-user $AdminUser `
    --admin-password $AdminPassword `
    --sku-name Standard_B1ms `
    --tier Burstable `
    --storage-size 32 `
    --version 8.0 `
    --public-access 0.0.0.0
if ($LASTEXITCODE -ne 0) {
    throw "MySQL server creation failed."
}

Write-Host "Creating database..."
az mysql flexible-server db create `
    --resource-group $ResourceGroup `
    --server-name $ServerName `
    --database-name $DatabaseName
if ($LASTEXITCODE -ne 0) {
    throw "Database creation failed."
}

Write-Host ""
Write-Host "Azure MySQL created."
Write-Host "Server: $ServerName.mysql.database.azure.com"
Write-Host "Database: $DatabaseName"
