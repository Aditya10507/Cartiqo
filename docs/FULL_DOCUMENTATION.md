# Cartiqo (SwiftCart) Project Summary

_Generated on 2026-03-25 from the current codebase._

## One-Line Description

Cartiqo is a Flutter + Firebase retail checkout and mall-operations platform: a customer-facing scan-to-bill app and a web portal for admins and mall managers to manage malls, subscriptions, managers, inventory, QR/barcode assets, and sales history.

## What Exists In This Repo

- Flutter app (Android/iOS/Web) built with Provider state management.
- Web portal homepage with Admin login and Mall Manager login entry points.
- Firestore-backed data model for malls, managers, products, barcodes, payments, promotions, announcements, staff activity, support requests, and user profiles.
- CSV export utilities and PDF/print utilities for labels and receipts.
- Firebase Cloud Functions (Node.js/TypeScript) for OTP flows (phone OTP SMS, email OTP signup, password reset OTP) plus scheduled cleanup jobs.

## Primary Roles and Portals

- Customer/App User: signs up/logs in (email/password or OTP), selects a mall, scans items, builds cart, and checks out.
- Admin (Web): manages malls, subscriptions, managers, and operational dashboards; monitors support requests and announcements.
- Mall Manager (Web): logs in via manager ID + password; manages products, barcodes, billing settings, promotions, and sales analytics with CSV export.


---

# Models, Tools, and Technologies

_Generated on 2026-03-25 from the current codebase._

## Core App Stack

- Flutter (Dart) for Android/iOS/Web UI.
- Provider for state management.
- Firebase Core + Cloud Firestore as the primary backend database.
- Firebase Auth for user authentication.
- Firebase Hosting for web deployment.

## Operational/Feature Libraries

- mobile_scanner + vibration: barcode/QR scanning with haptics feedback.
- pdf + printing: generate printable PDFs (labels/receipts) and trigger print dialogs.
- csv + file_picker + web download helper: export operational data (sales dashboard, subscriptions, etc.) as CSV.
- crypto (sha256): hashing for manager/admin credential workflows stored in Firestore (as implemented in providers).
- qr_flutter: QR generation for mall assets and labels.

## Firebase Cloud Functions Stack (functions/)

- Runtime: 20
- TypeScript build pipeline (`npm run build`).
- firebase-admin + firebase-functions.
- Twilio for SMS OTP sending (requires Twilio env vars).
- Resend (HTTP API) for email OTP flows (requires API key).

## Flutter Dependencies (pubspec.yaml)

### Dependencies

```yaml
flutter: (sdk)
cupertino_icons: ^1.0.8
firebase_core: ^4.4.0
cloud_firestore: ^6.1.2
firebase_auth: ^6.1.4
provider: ^6.1.5+1
mobile_scanner: ^7.2.0
vibration: ^2.1.0
image_picker: ^1.1.2
path_provider: ^2.1.5
crypto: ^3.0.3
qr_flutter: ^4.1.0
pdf: ^3.11.3
printing: ^5.14.2
csv: ^6.0.0
file_picker: ^8.0.0
```

### Dev Dependencies

```yaml
flutter_test: (sdk)
flutter_lints: ^6.0.0
```


---

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


---

# Data Models (Dart)

_Generated on 2026-03-25 from lib/models._

## Model Files

- lib/models/admin.dart (50 lines)
- lib/models/cart_item.dart (20 lines)
- lib/models/mall_billing_settings.dart (51 lines)
- lib/models/mall_manager_account.dart (37 lines)
- lib/models/mall_manager_profile.dart (70 lines)
- lib/models/mall_product.dart (62 lines)
- lib/models/mall_subscription.dart (103 lines)

## Notes

These are the primary client-side data structures used to map Firestore documents into strongly-typed Dart objects.

### lib/models/admin.dart

- Classes: Admin

### lib/models/cart_item.dart

- Classes: CartItem

### lib/models/mall_billing_settings.dart

- Classes: MallBillingSettings

### lib/models/mall_manager_account.dart

- Classes: MallManagerAccount

### lib/models/mall_manager_profile.dart

- Classes: MallManagerProfile

### lib/models/mall_product.dart

- Classes: MallProduct

### lib/models/mall_subscription.dart

- Classes: MallSubscription


---

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


---

# Code Walkthrough (Inventory)

_Generated on 2026-03-25 from the current lib/ layout._

## Screens (UI)

- lib/screens/add_mall_screen.dart: AddMallScreen, _AddMallScreenState
- lib/screens/admin_dashboard_screen.dart: AdminDashboardScreen, _AdminDashboardScreenState, _StatCard, _MallCard
- lib/screens/admin_login_screen.dart: AdminLoginScreen, _AdminLoginScreenState
- lib/screens/barcode_library_screen.dart: BarcodeLibraryScreen, _BarcodeLibraryScreenState, _HeaderPanel, _BarcodeLibraryCard, _QueuePanel, _MobileQueueBar, _PrintHistoryEntry, _EmptyBarcodeState
- lib/screens/barcode_scanner_screen.dart: BarcodeScannerScreen, _BarcodeScannerScreenState, _CornerHighlight, _CornerPainter
- lib/screens/cart_screen.dart: CartScreen
- lib/screens/checkout_flow_screen.dart: CheckoutReviewScreen, PaymentMethodScreen, _PaymentMethodScreenState, PaymentGatewayScreen, _PaymentGatewayScreenState, PaymentSuccessScreen, _CheckoutHeader, _BillItemCard, _SummaryCard, _SummaryRow, _PaymentMethodOption
- lib/screens/email_otp_forgot_password_screen.dart: EmailOtpForgotPasswordScreen, _EmailOtpForgotPasswordScreenState
- lib/screens/email_otp_signup_screen.dart: EmailOtpSignupScreen, _EmailOtpSignupScreenState
- lib/screens/email_verification_pending_screen.dart: EmailVerificationPendingScreen
- lib/screens/import_export_screen.dart: ImportExportScreen, _ImportExportScreenState, _ImportProgressDialog, _ImportProgressDialogState
- lib/screens/mall_billing_settings_screen.dart: MallBillingSettingsScreen, _MallBillingSettingsScreenState
- lib/screens/mall_details_screen.dart: MallDetailsScreen, _SectionCard, _DetailRow, _ManagerTile
- lib/screens/mall_manager_details_screen.dart: MallManagerDetailsScreen, _InfoRow, _StatusChip
- lib/screens/mall_manager_login_screen.dart: MallManagerLoginScreen, _MallManagerLoginScreenState
- lib/screens/mall_manager_profile_screen.dart: MallManagerProfileScreen, _MallManagerProfileScreenState
- lib/screens/mall_managers_screen.dart: MallManagersScreen, _StatusChip
- lib/screens/mall_qr_library_screen.dart: MallQrLibraryScreen, _MallQrLibraryScreenState, _MallQrCard, _EmptyMallQrState
- lib/screens/mall_qr_scanner_screen.dart: MallQrScannerScreen, _MallQrScannerScreenState, _CornerBracketPainter
- lib/screens/mall_select_screen.dart: MallSelectScreen, _MallSelectScreenState, _QuickChip
- lib/screens/manage_subscription_screen.dart: ManageSubscriptionScreen, _ManageSubscriptionScreenState
- lib/screens/phone_otp_auth_screen.dart: PhoneOtpAuthScreen, _PhoneOtpAuthScreenState
- lib/screens/product_search_screen.dart: ProductSearchScreen, _ProductSearchScreenState, _SearchProductCard
- lib/screens/products_management_screen.dart: ProductsManagementScreen, _ProductsManagementScreenState, _TopToolbar, _FilterBar, _SummaryCard, _ProductsTable, _EmptyProductState, _BillingSettingsDialog, _BillingSettingsDialogState, _ProductCard, _MetricChip, _AddProductDialog, _AddProductDialogState
- lib/screens/sales_history_screen.dart: SalesHistoryScreen, _SalesHistoryScreenState, _HeroHeader, _FilterBar, _PaymentsTable, _Pill, _StatusPill, _Card, _Metric, _ConsolidatedSummaryCard, _SummaryRow, _TrendBucketsCard, _Bucket, _BucketAccumulator
- lib/screens/scan_product_screen.dart: ScanProductScreen, _ScanProductScreenState
- lib/screens/user_auth_screen.dart: UserAuthGateScreen, UserAuthScreen, _UserAuthScreenState, _ForgotPasswordDialog, _ForgotPasswordDialogState
- lib/screens/user_profile_screen.dart: UserProfileScreen, _PersonalInfoTab, _BillsTab, _PaymentsTab, _InfoCard, _StatusChip, _SectionTitle, _ProfileAvatar, _AvatarPreset
- lib/screens/web_admin_dashboard_screen.dart: WebAdminDashboardScreen, _WebAdminDashboardScreenState, _AdminSidebar, _AdminHeader, _DirectoryPanel, _DirectoryPanelState, _GridHint, _PlanBadge, _HealthBadge, _ActivityPanel, _SubscriptionHealthPanel, _AnnouncementsPanel, _SupportPanel, _ReportsPanel, _ActionStrip, _ActionData, _SideTile, _StatCard, _Panel, _MiniRow, _AnnouncementDialog, _AnnouncementDialogState
- lib/screens/web_mall_manager_dashboard_screen.dart: WebMallManagerDashboardScreen, _ManagerSidebar, _ManagerHeader, _InventoryPanel, _InventoryPanelState, _GridHint, _StockBadge, _AlertsPanel, _BillingPreviewPanel, _TopProductsPanel, _TransactionsPanel, _PromotionsPanel, _SearchPanel, _StaffActivityPanel, _ActionRow, _ActionItem, _MenuTile, _ManagerStatCard, _Panel, _MiniCard, _PromotionDialog, _PromotionDialogState
- lib/screens/web_portal_home_screen.dart: WebPortalHomeScreen, _TopBar, _HeroSection, _PortalSection, _DemoSection, _PricingSection, _CtaSection, _SectionShell, _AdaptiveList, _PortalCard, _DarkPanel, _DarkPanelItem, _InfoCard, _PlanCard, _PreviewRow, _BillLine, _Pill, _FooterSection, _SupportRequestDialog, _SupportRequestDialogState
- lib/screens/web_portal_home_screen_stub.dart: WebPortalHomeScreen

## Providers (State + Firestore)

- lib/providers/admin_provider.dart: AdminProvider
- lib/providers/cart_provider.dart: CartProvider
- lib/providers/mall_manager_provider.dart: MallManagerProvider
- lib/providers/user_auth_provider.dart: UserAuthProvider

## Services (Export/Print/Utilities)

- lib/services/barcode_print_service.dart: BarcodeLabelData, BarcodePrintOptions, BarcodePrintService
- lib/services/barcode_service.dart: BarcodeService
- lib/services/csv_service.dart: CsvService, CsvImportResult
- lib/services/file_download_service.dart: 
- lib/services/file_download_service_stub.dart: 
- lib/services/file_download_service_web.dart: 
- lib/services/history_print_service.dart: HistoryPrintService
- lib/services/mall_qr_print_service.dart: MallQrLabelData, MallQrPrintService
- lib/services/page_transitions.dart: SlidePageTransition, FadePageTransition, RotatePageTransition

## Widgets (Reusable UI Components)

- lib/widgets/animated_button.dart: AnimatedButton, _AnimatedButtonState
- lib/widgets/manager_sales_dashboard_panel.dart: ManagerSalesDashboardPanel, _ManagerSalesDashboardPanelState, _SalesMetricCard, _AnalysisChip, _HintChip, _SalesSummary, _GroupedSalesAccumulator, _GroupedSalesRow
- lib/widgets/product_barcode_widget.dart: ProductBarcodeWidget, _Ean13BarcodePainter
- lib/widgets/swiftcart_logo.dart: SwiftCartLogo, _SwiftCartLogoPainter

## Cloud Functions Exports

- sendPhoneOtp
- cleanupExpiredOtps
- verifyOtpManual
- logOtpEvent
- sendEmailOtpSignup
- sendPasswordResetOtp
- cleanupExpiredEmailOtps


---

# Deployment and Operations

_Generated on 2026-03-25._

## Web Hosting (Firebase Hosting)

Build + deploy steps:

```powershell
cd C:\Users\GS\swiftcart_app
flutter pub get
flutter build web --release
firebase deploy --only hosting
```

## Cloud Functions (Firebase Functions)

Local build steps:

```powershell
cd C:\Users\GS\swiftcart_app\functions
npm ci
npm run build
firebase deploy --only functions
```

### Important: Billing Plan Requirement

Deploying Cloud Functions can require enabling Google APIs (Cloud Build, Artifact Registry). If your Firebase project is on the free plan, deploy may be blocked until upgraded to Blaze.

## Required Secrets/Environment Variables (Functions)

- TWILIO_ACCOUNT_SID
- TWILIO_AUTH_TOKEN
- TWILIO_PHONE_NUMBER
- RESEND_API_KEY (if using Resend email flow)
- FROM_EMAIL (optional override)

