# Malls Migration

## What This Does

Imports Firestore `malls` documents into the MySQL `malls` table.

Script:

- `tools/migrate_malls_firestore_to_mysql.js`

## Before You Run It

1. Keep local MySQL running
2. Keep the `swiftcart_dev` database created
3. Make sure the backend migration has already been applied
4. Download a Firebase service account key JSON for project `swiftcart-69c08`
5. Save it here:

```text
tools/serviceAccountKey.json
```

## Install Tool Dependencies

From the repo root:

```powershell
cd tools
npm install
cd ..
```

## Run The Malls Import

From the repo root:

```powershell
$env:MYSQL_CONNECTION_STRING = "mysql://root:YOUR_PASSWORD@localhost:3306/swiftcart_dev"
node .\tools\migrate_malls_firestore_to_mysql.js
```

## Verify

Open MySQL:

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
```

Then run:

```sql
USE swiftcart_dev;
SELECT mall_id, name, is_active FROM malls;
```

## Notes

- The script is idempotent for mall IDs because it uses `ON DUPLICATE KEY UPDATE`
- This migrates only the `malls` collection for now
- Managers, users, products, barcodes, payments, and bills still need separate migration steps
