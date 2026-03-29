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

