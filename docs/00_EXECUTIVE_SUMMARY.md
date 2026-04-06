# Executive Summary

Cartiqo / SwiftCart is a retail checkout and mall-management platform built with Flutter on the client side and ASP.NET Core + MySQL on the backend.

## Business Scope

The system supports three core personas:

- customer
- mall manager
- system admin

## Customer-Side Capabilities

- browse/select a mall
- search products
- scan barcodes
- checkout and store billing history
- create an account using email OTP verification
- sign in with username/password
- reset password using email OTP

## Mall Manager Capabilities

- log in to a mall-specific dashboard
- manage products and barcode-linked inventory
- update mall billing settings
- create and remove promotions
- review sales and payment history
- track staff activity

## Admin Capabilities

- log in to the admin dashboard
- create, update, and deactivate malls
- manage mall manager accounts
- publish announcements
- track support/demo requests
- review recent payments

## Technical Direction

The project has been fully migrated away from Firebase runtime dependencies. The current production stack is:

- Flutter
- Provider
- ASP.NET Core Web API
- Entity Framework Core
- MySQL
- Azure App Service
- Azure Database for MySQL Flexible Server
- Azure Static Website Hosting

