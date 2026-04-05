# Products Migration

## What This Does

Imports Firestore mall `products` and `barcodes` subcollections into MySQL.

Script:

- `tools/migrate_products_firestore_to_mysql.js`

## Run

```powershell
$env:MYSQL_CONNECTION_STRING = "mysql://root:YOUR_PASSWORD@localhost:3306/swiftcart_dev"
node .\tools\migrate_products_firestore_to_mysql.js
```

If your password contains `@`, use `%40`.

## Verify

```sql
USE swiftcart_dev;
SELECT mall_id, product_id, name, barcode FROM products ORDER BY mall_id, name;
SELECT mall_id, barcode, product_id FROM barcodes ORDER BY mall_id, barcode;
```
