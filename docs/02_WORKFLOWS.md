# Workflows

## 1. Customer Flow

### Signup

1. User opens the customer auth screen.
2. User enters first name, last name, username, email, password, and confirm password.
3. App requests an email OTP from the backend.
4. User verifies the OTP.
5. Backend creates the account and returns a session token.

### Sign In

1. User enters username and password.
2. App calls `POST /api/auth/users/login`.
3. Backend validates credentials and returns the user session.

### Forgot Password

1. User enters registered email.
2. App requests a password reset OTP.
3. User enters OTP and a new password.
4. Backend updates the stored password hash.

### Shopping And Checkout

1. User selects a mall.
2. App loads products from public mall endpoints.
3. User searches or scans items.
4. Cart is built in the Flutter app.
5. Checkout is posted to the backend.
6. Bill and payment records are stored in MySQL.

## 2. Mall Manager Flow

1. Manager logs in with manager ID and password.
2. App loads profile, products, billing settings, promotions, and payment history.
3. Manager can:
   - add/update/delete products
   - view barcode-linked inventory
   - manage promotions
   - update billing settings
   - view staff activity and payments

## 3. Admin Flow

1. Admin logs in with email and password.
2. Dashboard loads malls, manager counts, recent payments, announcements, and support requests.
3. Admin can:
   - add or edit malls
   - deactivate malls
   - create mall managers
   - reset manager passwords
   - activate/deactivate manager accounts
   - create announcements
   - update support request status

## 4. Website Public Flow

The web portal home screen acts as the public entrypoint and routes users into:

- customer-side usage
- admin-side usage
- mall-manager usage
- support/demo request submission

