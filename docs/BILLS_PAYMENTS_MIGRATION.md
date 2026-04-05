# Bills And Payments Migration

## What This Does

Imports Firestore user and mall `bills` / `payments` subcollections into MySQL.

Script:

- `tools/migrate_bills_payments_firestore_to_mysql.js`

## Run

```powershell
$env:MYSQL_CONNECTION_STRING = "mysql://root:YOUR_PASSWORD@localhost:3306/swiftcart_dev"
node .\tools\migrate_bills_payments_firestore_to_mysql.js
```

If your password contains `@`, use `%40`.

## Verify

```sql
USE swiftcart_dev;
SELECT bill_id, bill_number, mall_id, user_id, total FROM bills ORDER BY created_at DESC;
SELECT payment_id, payment_number, mall_id, user_id, amount, method FROM payments ORDER BY created_at DESC;
```
