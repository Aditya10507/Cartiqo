# Users Migration

## What This Does

Imports Firestore `users` documents into the MySQL `users` table.

Script:

- `tools/migrate_users_firestore_to_mysql.js`

## Before You Run It

1. Apply the latest backend EF migration
2. Keep local MySQL running
3. Keep `tools/serviceAccountKey.json` in place

## Run The Users Import

From the repo root:

```powershell
$env:MYSQL_CONNECTION_STRING = "mysql://root:YOUR_PASSWORD@localhost:3306/swiftcart_dev"
node .\tools\migrate_users_firestore_to_mysql.js
```

If your password contains `@`, use `%40` in the URL string.

## Verify

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
```

Then:

```sql
USE swiftcart_dev;
SELECT uid, full_name, email, phone, provider FROM users ORDER BY created_at DESC;
```

## Note

This migrates profile records only.
Firebase Auth sign-in is still separate until the auth migration phase is completed.
