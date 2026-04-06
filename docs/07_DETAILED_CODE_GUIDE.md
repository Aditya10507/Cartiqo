# Detailed Code Guide

## Frontend Layers

### 1. Screen Layer

The `lib/screens` folder contains the UI workflows for:

- customer auth and profile
- mall selection and shopping
- scan and checkout
- admin login and dashboard
- mall manager login and dashboard
- public website entry pages

### 2. Provider Layer

Providers are the main state containers used by the UI:

- `AdminProvider`
- `MallManagerProvider`
- `UserAuthProvider`
- `CartProvider`

Each provider wraps the corresponding API service and exposes data plus loading/error state for widgets.

### 3. Service Layer

Service classes are the HTTP integration layer. They:

- build URLs using `ApiConfig.baseUrl`
- serialize request payloads
- parse backend JSON
- throw meaningful exceptions for UI handling

## Backend Layers

### 1. Controllers

Controllers define route groups and map HTTP requests to domain operations.

### 2. Models

The backend separates:

- request/response DTOs
- entity models
- API-specific payload models

### 3. Data Context

`SwiftCartDbContext` defines the tables and column mappings for the production MySQL schema.

### 4. Services

Backend service classes currently include:

- password hashing support
- JWT token generation
- email OTP sending

## Migration Notes

The codebase no longer depends on Firebase runtime packages. Data and authentication flows now run through:

- Flutter service classes
- ASP.NET Core controllers
- MySQL persistence
- Azure hosting

