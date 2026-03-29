# App and Website Workflows

_Generated on 2026-03-25 from the current codebase._

## Customer App Workflow (Mobile)

- Auth: Email/password signup + email verification OR phone OTP login.
- Mall selection: choose a mall from Firestore (`malls` collection).
- Scan-to-cart: barcode scanner reads product barcode; maps barcode to product in the selected mall.
- Cart management: add/remove items and adjust quantities.
- Checkout: billing settings (GST/tax/extra charges) applied; payment record is created in Firestore under mall payments.
- History: user profile provides access to previous bills and payments (per-user subcollections).

## Admin Web Portal Workflow

- Admin login (web) then access Admin dashboard.
- Create and manage malls and subscriptions (also stored in `mall_subscriptions`).
- Manage mall managers (multiple managers per mall): create/update/reset credentials, view manager list for a mall.
- Monitor recent activity and payments (uses `collectionGroup('payments')` watch).
- Announcements + support requests workflows (create announcements, triage support tickets).
- Exporting: subscription/summary and other admin tables can be exported as CSV (where enabled).

## Mall Manager Web Portal Workflow

- Manager login using manager ID + password (lookup via `manager_index` and `malls/{mallId}/managers`).
- Inventory: create/update/delete products in `malls/{mallId}/products`.
- Barcode mapping: maintain `malls/{mallId}/barcodes` mapping for fast scanning.
- Billing settings: update GST/tax/extra charges stored under the mall document (`billingSettings`).
- Promotions: create and manage promotions under `malls/{mallId}/promotions`.
- Sales dashboard: filter and consolidate payments, group analysis (day/week/month/year), refresh button, and CSV export.
- Staff activity logging: key actions recorded under `malls/{mallId}/staff_activity`.

