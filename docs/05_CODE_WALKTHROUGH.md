# Code Walkthrough

## Flutter App Structure

### App Entry

- [main.dart](/c:/Users/GS/swiftcart_app/lib/main.dart)
- [app.dart](/c:/Users/GS/swiftcart_app/lib/app/app.dart)

`main.dart` starts the Flutter app. `app.dart` wires up the main providers and launches the web portal home screen.

### Providers

- [admin_provider.dart](/c:/Users/GS/swiftcart_app/lib/providers/admin_provider.dart)
- [mall_manager_provider.dart](/c:/Users/GS/swiftcart_app/lib/providers/mall_manager_provider.dart)
- [user_auth_provider.dart](/c:/Users/GS/swiftcart_app/lib/providers/user_auth_provider.dart)
- [cart_provider.dart](/c:/Users/GS/swiftcart_app/lib/providers/cart_provider.dart)

Responsibilities:

- `AdminProvider`: admin login, mall CRUD, manager operations, announcements, support requests, recent payments
- `MallManagerProvider`: manager login, product CRUD, promotions, staff activity, billing settings, payment reads
- `UserAuthProvider`: customer signup/signin/password reset and user-profile/history API coordination
- `CartProvider`: client-side cart state

### API Service Layer

- [api_config.dart](/c:/Users/GS/swiftcart_app/lib/services/api_config.dart)
- [admin_api_service.dart](/c:/Users/GS/swiftcart_app/lib/services/admin_api_service.dart)
- [mall_manager_api_service.dart](/c:/Users/GS/swiftcart_app/lib/services/mall_manager_api_service.dart)
- [storefront_api_service.dart](/c:/Users/GS/swiftcart_app/lib/services/storefront_api_service.dart)
- [user_auth_api_service.dart](/c:/Users/GS/swiftcart_app/lib/services/user_auth_api_service.dart)
- [user_profile_api_service.dart](/c:/Users/GS/swiftcart_app/lib/services/user_profile_api_service.dart)

The Flutter app now communicates with the backend only through this service layer.

## Backend Structure

### Entry And Configuration

- [Program.cs](/c:/Users/GS/swiftcart_app/backend/SwiftCart.Api/Program.cs)
- [Configuration](/c:/Users/GS/swiftcart_app/backend/SwiftCart.Api/Configuration)

The backend sets up:

- MySQL connection
- JWT authentication
- CORS
- controllers
- email OTP settings

### Data Layer

- [SwiftCartDbContext.cs](/c:/Users/GS/swiftcart_app/backend/SwiftCart.Api/Data/SwiftCartDbContext.cs)
- [Migrations](/c:/Users/GS/swiftcart_app/backend/SwiftCart.Api/Data/Migrations)
- [Entities](/c:/Users/GS/swiftcart_app/backend/SwiftCart.Api/Models/Entities)

### Controllers

Main controller groups:

- admin/auth: `AuthController`
- health/setup: `HealthController`, `SetupController`
- malls/managers: `MallsController`, `MallManagersController`
- manager auth/profile/operations: `MallManagerAuthController`, `MallManagerProfileController`, `MallManagerOperationsController`
- products/payments/bills: `ProductsController`, `PaymentsController`, `BillsController`
- public storefront and profile access: `PublicStorefrontController`, `PublicUsersController`
- customer auth: `UserEmailOtpAuthController`
- utility/admin content: `AnnouncementsController`, `SupportRequestsController`, `UsersController`

## API Surface Summary

### Health

- `GET /api/health`

### Admin

- `POST /api/auth/admin/login`
- `GET /api/malls`
- `POST /api/malls`
- `PUT /api/malls/{mallId}`
- `POST /api/malls/{mallId}/deactivate`
- `PUT /api/malls/{mallId}/billing-settings`
- `GET /api/malls/{mallId}/managers`
- `POST /api/malls/{mallId}/managers`

### Mall Manager

- `POST /api/auth/mall-manager/login`
- `GET /api/mall-manager/profile`
- `PUT /api/mall-manager/profile`
- `GET /api/mall-manager/promotions`
- `POST /api/mall-manager/promotions`
- `DELETE /api/mall-manager/promotions/{promotionId}`
- `GET /api/mall-manager/staff-activity`

### Customer/Public

- `POST /api/auth/users/register/request-otp`
- `POST /api/auth/users/register/verify-otp`
- `POST /api/auth/users/login`
- `POST /api/auth/users/password/request-otp`
- `POST /api/auth/users/password/reset`
- `GET /api/public/malls/{mallId}/products`
- `GET /api/public/malls/{mallId}/products/barcode/{barcode}`
- `GET /api/public/malls/{mallId}/billing-settings`
- `POST /api/public/malls/{mallId}/checkout`
- `GET /api/public/users/{uid}`
- `PUT /api/public/users/{uid}`
- `GET /api/public/users/{uid}/bills`
- `GET /api/public/users/{uid}/payments`

