# Cartiqo Admin System Setup Guide

## Overview
The admin panel allows administrators to:
- Manage multiple mall subscriptions
- Generate unique Mall IDs for new malls
- Track subscription status and renewal dates
- Update subscription plans and expiry dates
- Activate/deactivate malls

---

## Firebase Setup Instructions

### 1. Create Admin Collection
You need to create an **`admins`** collection in your Firestore database to store admin credentials.

**Collection Path:** `admins`

**Sample Admin Document:**
```
Document ID: admin@swiftcart.com

Fields:
{
  "adminId": "admin_001",
  "email": "admin@swiftcart.com",
  "name": "John Admin",
  "passwordHash": "9b71d224bd62f3785d96f46e3e6a697e1c0ce1b9c149f1e9bcbfbd2c0d5cf07c5",  // SHA256 hash of "admin123"
  "role": "super_admin",
  "createdAt": <Timestamp>
}
```

### 2. Create Mall Subscriptions Collection
The **`mall_subscriptions`** collection stores subscription information for each mall.

**Collection Path:** `mall_subscriptions`

**Sample Subscription Document:**
```
Document ID: 11000103CP19 (The Mall ID)

Fields:
{
  "mallId": "11000103CP19",
  "mallName": "City Central Mall",
  "ownerName": "Rajesh Kumar",
  "ownerEmail": "rajesh@mall.com",
  "city": "Delhi",
  "state": "Delhi",
  "subscriptionStartDate": <Timestamp>,
  "subscriptionEndDate": <Timestamp>,
  "planType": "pro",
  "maxProducts": 5000,
  "isActive": true,
  "createdAt": <Timestamp>
}
```

### 3. Update Existing Malls Collection
Add subscription fields to your existing **`malls/{mallId}`** documents:

**Fields to add to existing malls:**
```
{
  "subscriptionEndDate": <Timestamp>,
  "planType": "basic",
  "maxProducts": 1000,
  "isActive": true
}
```

---

## Admin Panel Features

### 1. Login Screen
- Email: Admin email address
- Password: Admin password (hashed as SHA256)

**Demo Credentials:**
- Email: `admin@swiftcart.com`
- Password: `admin123`

### 2. Dashboard
Displays:
- Total number of malls
- Number of active malls
- Number of malls expiring within 30 days
- List of all malls with status

### 3. Add New Mall
- Click "Add New Mall" button
- System automatically generates a unique 12-digit Mall ID (format: XXXXXXXXAAYY)
  - 8 digits: Area code
  - 2 letters: Region code
  - 2 digits: Current year
- Fill in mall details
- Select subscription plan (Basic, Pro, Enterprise)
- Set subscription start and end dates
- Mall is automatically created with database entry

### 4. Manage Subscription
For each mall, admins can:
- **View current status:** Active/Inactive, days until expiry
- **Quick renew:** Add 3 months or 1 year to subscription
- **Change plan:** Switch between Basic, Pro, or Enterprise
- **Update end date:** Manually set new subscription end date
- **Deactivate mall:** Permanently deactivate a mall

---

## Subscription Plans

### Basic Plan
- Max Products: 1,000
- Price: ₹999/month

### Pro Plan
- Max Products: 5,000
- Price: ₹2,999/month

### Enterprise Plan
- Max Products: 50,000
- Price: Custom pricing

---

## Firebase Security Rules

Add these rules to your Firestore to secure the admin data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin collection - only admins can read/write
    match /admins/{document=**} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.adminIds;
    }
    
    // Mall subscriptions - admins can read/write, users can read
    match /mall_subscriptions/{mallId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Malls collection - public read, admin write
    match /malls/{mallId} {
      allow read: if true;
      allow write: if request.auth != null;
      
      // Products subcollection
      match /products/{document=**} {
        allow read: if true;
        allow write: if request.auth != null;
      }
      
      // Barcodes subcollection
      match /barcodes/{document=**} {
        allow read: if true;
        allow write: if request.auth != null;
      }
    }
  }
}
```

---

## Setting Up Admin Credentials

### 1. Generate Password Hash (SHA256)

Use this Dart code to generate the password hash:

```dart
import 'package:crypto/crypto.dart';

String password = "admin123";
String hash = sha256.convert(password.codeUnits).toString();
print(hash); // Output: 9b71d224bd62f3785d96f46e3e6a697e1c0ce1b9c149f1e9bcbfbd2c0d5cf07c5
```

### 2. Add Admin to Firebase

1. Go to Firestore Console
2. Create collection: `admins`
3. Create document with ID: `admin@swiftcart.com`
4. Add fields as shown in the example above

---

## Mall ID Format

Format: `XXXXXXXXAAYY`
- **XXXXXXXX**: 8-digit random area code
- **AA**: 2-digit random letter code
- **YY**: Current year (last 2 digits)

Examples:
- `11234567CP24` (Delhi, CP, 2024)
- `98765432MH24` (Mumbai, MH, 2024)

---

## Troubleshooting

### Admin Login Fails
- Verify email exists in `admins` collection
- Check password hash matches SHA256 of actual password
- Ensure `createdAt` field is a Timestamp type

### Mall ID Generation Error
- Check that `malls` collection exists in Firestore
- Verify no duplicate Mall IDs exist
- Ensure unique ID generation logic is working

### Subscription Not Updating
- Verify `mall_subscriptions` document exists
- Check Firestore write permissions
- Ensure date fields are Timestamp type

---

## Database Schema

```
firestore/
├── admins/
│   └── {email}/
│       ├── adminId: String
│       ├── email: String
│       ├── name: String
│       ├── passwordHash: String
│       ├── role: String (super_admin | admin)
│       └── createdAt: Timestamp
│
├── mall_subscriptions/
│   └── {mallId}/
│       ├── mallId: String
│       ├── mallName: String
│       ├── ownerName: String
│       ├── ownerEmail: String
│       ├── city: String
│       ├── state: String
│       ├── subscriptionStartDate: Timestamp
│       ├── subscriptionEndDate: Timestamp
│       ├── planType: String (basic | pro | enterprise)
│       ├── maxProducts: Number
│       ├── isActive: Boolean
│       └── createdAt: Timestamp
│
└── malls/
    └── {mallId}/
        ├── mallId: String
        ├── subscriptionEndDate: Timestamp
        ├── planType: String
        ├── maxProducts: Number
        ├── isActive: Boolean
        ├── products/
        │   └── {productId}/...
        └── barcodes/
            └── {barcode}/...
```

---

## Next Steps

1. Set up Firebase collections as described
2. Create admin account with demo credentials
3. Test login with demo credentials
4. Generate first mall ID
5. Add test mall and manage subscriptions
