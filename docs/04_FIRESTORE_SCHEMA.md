# Firestore Collections and Schema (Inferred)

_Generated on 2026-03-25 by scanning Firestore calls in lib/ and functions/._

## Top-Level Collections Referenced

- _test
- admins
- announcements
- barcodes
- bills
- email_otp_signup
- mall_subscriptions
- malls
- manager_index
- managers
- password_reset_otp
- payments
- phone_otp
- products
- promotions
- staff_activity
- support_requests
- users

## Collection Group Queries Referenced

- payments

## Known Subcollection Patterns (Observed in Code)

- malls/{mallId}/products
- malls/{mallId}/barcodes
- malls/{mallId}/payments
- malls/{mallId}/managers
- malls/{mallId}/promotions
- malls/{mallId}/staff_activity
- users/{uid}/bills
- users/{uid}/payments

## OTP/Support Collections (Used by Auth + Functions)

- phone_otp (SMS OTP documents)
- email_otp_signup (email signup OTP documents)
- password_reset_otp (password reset OTP documents)
- support_requests (web portal contact/demo requests)

