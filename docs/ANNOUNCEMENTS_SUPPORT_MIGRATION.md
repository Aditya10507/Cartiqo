# Announcements And Support Migration

## What This Does

Imports Firestore `announcements` and `support_requests` into MySQL.

Script:

- `tools/migrate_announcements_support_firestore_to_mysql.js`

## Run

```powershell
$env:MYSQL_CONNECTION_STRING = "mysql://root:YOUR_PASSWORD@localhost:3306/swiftcart_dev"
node .\tools\migrate_announcements_support_firestore_to_mysql.js
```

If your password contains `@`, use `%40`.

## Verify

```sql
USE swiftcart_dev;
SELECT id, title, audience, created_by FROM announcements ORDER BY created_at DESC;
SELECT id, type, name, email, status FROM support_requests ORDER BY created_at DESC;
```
