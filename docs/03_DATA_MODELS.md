# Data Models

## Flutter Models

Key client-side model classes include:

- `Admin`
- `MallSubscription`
- `MallManagerAccount`
- `MallManagerProfile`
- `MallProduct`
- `MallBillingSettings`
- `AppUserSession`
- cart and checkout-related UI models

## Backend Entities

The MySQL schema is represented in [SwiftCartDbContext.cs](/c:/Users/GS/swiftcart_app/backend/SwiftCart.Api/Data/SwiftCartDbContext.cs).

Core entities:

- `AdminEntity`
- `MallEntity`
- `MallManagerEntity`
- `UserProfileEntity`
- `UserEmailOtpEntity`
- `UserPasswordResetOtpEntity`
- `ProductEntity`
- `BarcodeEntity`
- `BillEntity`
- `PaymentEntity`
- `AnnouncementEntity`
- `SupportRequestEntity`
- `PromotionEntity`
- `StaffActivityEntity`

## Important Data Domains

### Identity And Accounts

- admins
- mall managers
- users
- signup OTP records
- password reset OTP records

### Commerce

- malls
- products
- barcode lookup data
- bills
- payments

### Operations

- announcements
- support requests
- promotions
- staff activity

