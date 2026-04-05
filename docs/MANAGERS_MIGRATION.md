# Managers Migration

## What This Does

Imports Firestore mall manager documents into the MySQL `mall_managers` table.

Script:

- `tools/migrate_managers_firestore_to_mysql.js`

## Before You Run It

1. Apply the latest backend EF migration
2. Keep local MySQL running
3. Keep `tools/serviceAccountKey.json` in place

## Run The Managers Import

From the repo root:

```powershell
$env:MYSQL_CONNECTION_STRING = "mysql://root:YOUR_PASSWORD@localhost:3306/swiftcart_dev"
node .\tools\migrate_managers_firestore_to_mysql.js
```

If your password contains `@`, use `%40` in the URL string.

## Verify

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
```

Then:

```sql
USE swiftcart_dev;
SELECT manager_id, mall_id, is_active FROM mall_managers ORDER BY mall_id, manager_id;
```
