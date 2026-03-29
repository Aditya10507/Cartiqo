# Detailed Code Guide (Per File)

This section is designed for supervisors, auditors, and engineering reviewers. It explains the purpose of each major file and highlights the key classes and methods.

## lib/app/

## lib/app/app.dart

- Type: Flutter/Dart
- Lines: 43
- Classes/Exports: SwiftCartApp, AppModeSelector
- Key methods: build

### Header Excerpt

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/mall_manager_provider.dart';
import '../providers/user_auth_provider.dart';
import '../screens/web_portal_home_screen_stub.dart'
    if (dart.library.html) '../screens/web_portal_home_screen.dart';

class SwiftCartApp extends StatelessWidget {
  const SwiftCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        if (kIsWeb) ...[
          ChangeNotifierProvider(create: (_) => AdminProvider()),
          ChangeNotifierProvider(create: (_) => MallManagerProvider()),
        ],
        ChangeNotifierProvider(create: (_) => UserAuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cartiqo',
        theme: ThemeData(useMaterial3: true),
        home: const AppModeSelector(),
      ),
    );
  }
}

class AppModeSelector extends StatelessWidget {
  const AppModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebPortalHomeScreen();
  }
}
```

## lib/providers/

## lib/providers/admin_provider.dart

- Type: Flutter/Dart
- Lines: 694
- Classes/Exports: AdminProvider
- Key methods: _fetchMalls, _generateUniqueMallId, addNewMall, adminLogin, clearError, createAnnouncement, createMallManager, deactivateMall, generateNewMallId, getMallManagerCount, logout, refreshMalls, resetMallManagerPassword, setMallManagerActive, unlinkMallManager, updateMallSubscription, updateSupportRequestStatus

### Header Excerpt

```dart
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/admin.dart';
import '../models/mall_manager_account.dart';
import '../models/mall_subscription.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Admin? _currentAdmin;
  List<MallSubscription> _malls = [];
  bool _isLoading = false;
  String? _error;

  Admin? get currentAdmin => _currentAdmin;
  List<MallSubscription> get malls => _malls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Map<String, dynamic>>> watchAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<bool> createAnnouncement({
    required String title,
    required String message,
    String audience = 'all',
  }) async {
    try {
      await _firestore.collection('announcements').add({
        'title': title.trim(),
        'message': message.trim(),
        'audience': audience,
        'createdBy': _currentAdmin?.email ?? _currentAdmin?.name ?? 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Error creating announcement: $e';
      notifyListeners();
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> watchSupportRequests() {
    return _firestore
        .collection('support_requests')
```

## lib/providers/cart_provider.dart

- Type: Flutter/Dart
- Lines: 50
- Classes/Exports: CartProvider
- Key methods: addOrIncrement, clear, decrement, increment, remove

### Header Excerpt

```dart
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  // Keyed by barcode
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get total => _items.values.fold(0, (sum, item) => sum + item.lineTotal);

  int get totalItemsCount =>
      _items.values.fold(0, (sum, item) => sum + item.qty);

  void addOrIncrement(CartItem item) {
    if (_items.containsKey(item.barcode)) {
      _items[item.barcode]!.qty += 1;
    } else {
      _items[item.barcode] = item;
    }
    notifyListeners();
  }

  void increment(String barcode) {
    final item = _items[barcode];
    if (item == null) return;
    item.qty += 1;
    notifyListeners();
  }

  void decrement(String barcode) {
    final item = _items[barcode];
    if (item == null) return;

    item.qty -= 1;
    if (item.qty <= 0) _items.remove(barcode);
    notifyListeners();
  }

  void remove(String barcode) {
    _items.remove(barcode);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
```

## lib/providers/mall_manager_provider.dart

- Type: Flutter/Dart
- Lines: 736
- Classes/Exports: MallManagerProvider
- Key methods: _fetchProducts, _hashPassword, _logStaffActivity, addProduct, deleteProduct, deletePromotion, loadManagerProfile, loginAsMallManager, logout, savePromotion, testFirestoreConnection, updateBillingSettings, updateManagerProfile, updateProduct

### Header Excerpt

```dart
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/mall_manager_profile.dart';
import '../models/mall_billing_settings.dart';
import '../models/mall_product.dart';

class MallManagerProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentMallId;
  String? _currentManagerId;
  String? _currentManagerEmail;
  MallManagerProfile? _profile;
  List<MallProduct> _products = [];
  MallBillingSettings _billingSettings = const MallBillingSettings();
  bool _isLoading = false;
  String? _error;

  String? get currentMallId => _currentMallId;
  String? get currentManagerId => _currentManagerId;
  String? get currentManagerEmail => _currentManagerEmail;
  MallManagerProfile? get profile => _profile;
  List<MallProduct> get products => _products;
  MallBillingSettings get billingSettings => _billingSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String _hashPassword(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  Stream<List<Map<String, dynamic>>> watchMallPayments() {
    if (_currentMallId == null) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('malls')
        .doc(_currentMallId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchMallSalesPayments({int limit = 500}) {
    if (_currentMallId == null) {
      return Stream.value(const []);
    }

    return _firestore
```

## lib/providers/user_auth_provider.dart

- Type: Flutter/Dart
- Lines: 1263
- Classes/Exports: UserAuthProvider
- Key methods: _friendlyAuthMessage, _generateOtp, _setLoading, _storeUserProfile, cleanupExpiredOtps, clearError, createUserWithEmailPassword, dispose, isPasswordResetOtpValid, loginWithEmail, logout, refreshCurrentUser, resendCustomPhoneOtp, resendEmailVerification, resetPassword, saveCheckoutHistory, sendCustomPhoneOtp, sendEmailOtpSignup, sendPasswordResetOtp, sendPhoneOtp, signUpWithEmail, updateAvatarPreset, updateProfilePicture, updateUserProfile, verifyCustomPhoneOtp, verifyEmailOtpSignup, verifyPasswordResetOtp, verifyPhoneOtp

### Header Excerpt

```dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UserAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  int? _resendToken;
  bool _otpSent = false;
  String? _lastDemoPhoneOtp;

  UserAuthProvider() {
    _currentUser = _auth.currentUser;
    _authSubscription = _auth.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get otpSent => _otpSent;
  String? get verificationId => _verificationId;
  String? get userId => _currentUser?.uid;
  String? get lastDemoPhoneOtp => _lastDemoPhoneOtp;
  bool get canEnterApp {
    final user = _currentUser;
    if (user == null) return false;
    if (user.providerData.any((info) => info.providerId == 'phone')) {
      return true;
    }
    return user.emailVerified;
  }

  bool get needsEmailVerification {
    final user = _currentUser;
    if (user == null) return false;
    final isPhoneAccount = user.providerData.any(
      (info) => info.providerId == 'phone',
    );
    return !isPhoneAccount && user.email != null && !user.emailVerified;
  }

  Future<bool> signUpWithEmail({
    required String name,
```

## lib/screens/

## lib/screens/add_mall_screen.dart

- Type: Flutter/Dart
- Lines: 747
- Classes/Exports: AddMallScreen, _AddMallScreenState
- Key methods: _generateMallId, _selectEndDate, _selectStartDate, _submitForm, build, dispose

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import '../services/mall_qr_print_service.dart';

class AddMallScreen extends StatefulWidget {
  const AddMallScreen({super.key});

  @override
  State<AddMallScreen> createState() => _AddMallScreenState();
}

class _AddMallScreenState extends State<AddMallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mallNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _areaPincodeCtrl = TextEditingController();
  final _mallNumberCtrl = TextEditingController();
  final _mallCodeCtrl = TextEditingController();
  final _estYearCtrl = TextEditingController();

  String? _generatedMallId;
  String _selectedPlan = 'basic';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;
  bool _isSubmitting = false;

  final planDetails = {
    'basic': {'name': 'Basic', 'products': 1000, 'price': '₹999/month'},
    'pro': {'name': 'Pro', 'products': 5000, 'price': '₹2999/month'},
    'enterprise': {'name': 'Enterprise', 'products': 50000, 'price': 'Custom'},
  };

  @override
  void dispose() {
    _mallNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _areaPincodeCtrl.dispose();
    _mallNumberCtrl.dispose();
    _mallCodeCtrl.dispose();
    _estYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateMallId() async {
    // Validate required fields
    if (_areaPincodeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Area Pincode')),
      );
```

## lib/screens/admin_dashboard_screen.dart

- Type: Flutter/Dart
- Lines: 548
- Classes/Exports: AdminDashboardScreen, _AdminDashboardScreenState, _StatCard, _MallCard
- Key methods: _showLogoutDialog, build, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'add_mall_screen.dart';
import 'mall_qr_library_screen.dart';
import 'mall_managers_screen.dart';
import 'manage_subscription_screen.dart';
import '../app/app.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure malls are loaded when dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      // Refetch malls if the list is empty to ensure data consistency
      if (provider.malls.isEmpty) {
        provider.refreshMalls();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home instead of going back to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppModeSelector()),
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MallQrLibraryScreen(),
                ),
              ),
              icon: const Icon(Icons.qr_code_2_outlined),
              tooltip: 'Mall QR library',
            ),
            IconButton(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
```

## lib/screens/admin_login_screen.dart

- Type: Flutter/Dart
- Lines: 245
- Classes/Exports: AdminLoginScreen, _AdminLoginScreenState
- Key methods: _handleLogin, build, dispose

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../app/app.dart';
import '../providers/admin_provider.dart';
import '../widgets/swiftcart_logo.dart';
import 'admin_dashboard_screen.dart';
import 'web_admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.adminLogin(email, password);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              kIsWeb ? const WebAdminDashboardScreen() : const AdminDashboardScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminProvider.error ?? 'Login failed')),
      );
    }
```

## lib/screens/barcode_library_screen.dart

- Type: Flutter/Dart
- Lines: 785
- Classes/Exports: BarcodeLibraryScreen, _BarcodeLibraryScreenState, _HeaderPanel, _BarcodeLibraryCard, _QueuePanel, _MobileQueueBar, _PrintHistoryEntry, _EmptyBarcodeState
- Key methods: _copyBarcode, _matchesSearch, _printProducts, build, dispose

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/mall_product.dart';
import '../providers/mall_manager_provider.dart';
import '../services/barcode_print_service.dart';
import '../widgets/product_barcode_widget.dart';

class BarcodeLibraryScreen extends StatefulWidget {
  const BarcodeLibraryScreen({super.key});

  @override
  State<BarcodeLibraryScreen> createState() => _BarcodeLibraryScreenState();
}

class _BarcodeLibraryScreenState extends State<BarcodeLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _queuedProductIds = <String>{};
  final List<_PrintHistoryEntry> _history = [];

  String _searchQuery = '';
  String _categoryFilter = 'All';
  BarcodeLabelSize _labelSize = BarcodeLabelSize.standard;
  bool _showPrice = true;
  bool _showBrand = true;
  bool _showUnit = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MallManagerProvider>(
      builder: (context, provider, _) {
        final categories = <String>{
          'All',
          ...provider.products
              .map((p) => p.category)
              .where((c) => c.trim().isNotEmpty),
        }.toList()..sort();
        final filteredProducts =
            provider.products.where(_matchesSearch).where((product) {
              return _categoryFilter == 'All' ||
                  product.category == _categoryFilter;
            }).toList()..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
        final queuedProducts = provider.products
            .where((product) => _queuedProductIds.contains(product.productId))
            .toList();
        final wide = MediaQuery.of(context).size.width >= 1120;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Barcode Library'),
            actions: [
```

## lib/screens/barcode_scanner_screen.dart

- Type: Flutter/Dart
- Lines: 571
- Classes/Exports: BarcodeScannerScreen, _BarcodeScannerScreenState, _CornerHighlight, _CornerPainter
- Key methods: _buildCornerHighlights, _looksLikeMallId, _onDetect, _showSuccessAnimation, _switchCamera, _toggleTorch, _triggerScanFeedback, build, dispose, initState, paint, shouldRepaint

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _handled = false;
  bool _isTorchOn = false;
  bool _isScanning = true;
  bool _isFrameGlowing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.itf,
        BarcodeFormat.codabar,
      ],
      facing: CameraFacing.back,
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _looksLikeMallId(String s) {
    return RegExp(r'^\d{8}[A-Za-z]{2}\d{2}$').hasMatch(s.trim());
```

## lib/screens/cart_screen.dart

- Type: Flutter/Dart
- Lines: 338
- Classes/Exports: CartScreen
- Key methods: build

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'checkout_flow_screen.dart';
import '../widgets/swiftcart_logo.dart';

class CartScreen extends StatelessWidget {
  final String mallId;

  const CartScreen({super.key, required this.mallId});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4FBFF), Color(0xFFEAF1FF), Color(0xFFF8F0FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    const SwiftCartLogo(
                      size: 44,
                      showWordmark: false,
                      primaryColor: Color(0xFF0B5ED7),
                      accentColor: Color(0xFF12B886),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Cart',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Review items before checkout',
                            style: TextStyle(color: Color(0xFF607089)),
                          ),
                        ],
                      ),
                    ),
```

## lib/screens/checkout_flow_screen.dart

- Type: Flutter/Dart
- Lines: 752
- Classes/Exports: CheckoutReviewScreen, PaymentMethodScreen, _PaymentMethodScreenState, PaymentGatewayScreen, _PaymentGatewayScreenState, PaymentSuccessScreen, _CheckoutHeader, _BillItemCard, _SummaryCard, _SummaryRow, _PaymentMethodOption
- Key methods: _buildGatewayFields, _buildReference, _completePayment, build, dispose

### Header Excerpt

```dart
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/mall_billing_settings.dart';
import '../providers/cart_provider.dart';
import '../providers/user_auth_provider.dart';

class CheckoutReviewScreen extends StatelessWidget {
  final String mallId;

  const CheckoutReviewScreen({super.key, required this.mallId});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;
    final subtotal = cart.total;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('malls').doc(mallId).get(),
      builder: (context, snapshot) {
        final mallData = snapshot.data?.data();
        final billingSettings = MallBillingSettings.fromMap(
          mallData?['billingSettings'] as Map<String, dynamic>?,
        );
        final extraCharge = items.isEmpty
            ? 0
            : billingSettings.extraChargeAmount.round();
        final gst = ((subtotal + extraCharge) * (billingSettings.gstPercent / 100)).round();
        final otherTax =
            ((subtotal + extraCharge) * (billingSettings.taxPercent / 100)).round();
        final grandTotal = subtotal + extraCharge + gst + otherTax;

        return Scaffold(
          appBar: AppBar(title: const Text('Review Bill')),
          body: items.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _CheckoutHeader(
                      title: 'Scanned Products',
                      subtitle: 'Review all scanned products before payment.',
                    ),
                    const SizedBox(height: 16),
                    ...items.map((item) => _BillItemCard(item: item)),
                    const SizedBox(height: 16),
                    _SummaryCard(
                      mallId: mallId,
                      itemCount: items.length,
                      subtotal: subtotal,
                      extraChargeLabel: billingSettings.extraChargeLabel,
                      extraCharge: extraCharge,
                      gstPercent: billingSettings.gstPercent,
                      gst: gst,
                      otherTaxLabel: billingSettings.taxLabel,
```

## lib/screens/email_otp_forgot_password_screen.dart

- Type: Flutter/Dart
- Lines: 507
- Classes/Exports: EmailOtpForgotPasswordScreen, _EmailOtpForgotPasswordScreenState
- Key methods: _changeEmail, _formatTime, _resendOtp, _resetPassword, _sendOtp, _showSnack, _startResendCountdown, _verifyOtp, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_auth_provider.dart';
import '../widgets/swiftcart_logo.dart';

class EmailOtpForgotPasswordScreen extends StatefulWidget {
  const EmailOtpForgotPasswordScreen({super.key});

  @override
  State<EmailOtpForgotPasswordScreen> createState() =>
      _EmailOtpForgotPasswordScreenState();
}

class _EmailOtpForgotPasswordScreenState
    extends State<EmailOtpForgotPasswordScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  int _step = 1; // 1: Email, 2: OTP, 3: New Password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _resendCountdown = 0;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _timerController =
        AnimationController(duration: const Duration(seconds: 120), vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email');
      return;
    }
```

## lib/screens/email_otp_signup_screen.dart

- Type: Flutter/Dart
- Lines: 532
- Classes/Exports: EmailOtpSignupScreen, _EmailOtpSignupScreenState
- Key methods: _changeEmail, _completeSignup, _formatTime, _resendOtp, _sendOtp, _showSnack, _startResendCountdown, _verifyOtp, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_auth_provider.dart';
import '../widgets/swiftcart_logo.dart';

class EmailOtpSignupScreen extends StatefulWidget {
  const EmailOtpSignupScreen({super.key});

  @override
  State<EmailOtpSignupScreen> createState() => _EmailOtpSignupScreenState();
}

class _EmailOtpSignupScreenState extends State<EmailOtpSignupScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _nameController;

  int _step = 1; // 1: Email, 2: OTP, 3: Password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _resendCountdown = 0;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _nameController = TextEditingController();
    _timerController =
        AnimationController(duration: const Duration(seconds: 120), vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email');
```

## lib/screens/email_verification_pending_screen.dart

- Type: Flutter/Dart
- Lines: 169
- Classes/Exports: EmailVerificationPendingScreen
- Key methods: build

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_auth_provider.dart';
import 'mall_select_screen.dart';
import '../widgets/swiftcart_logo.dart';

class EmailVerificationPendingScreen extends StatelessWidget {
  final String email;

  const EmailVerificationPendingScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAuthProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B5ED7), Color(0xFF0F9B8E)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SwiftCartLogo(
                              size: 92,
                              showWordmark: false,
                              primaryColor: Color(0xFFEAF3FF),
                              accentColor: Color(0xFFD8FFF0),
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Verify your email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
```

## lib/screens/import_export_screen.dart

- Type: Flutter/Dart
- Lines: 921
- Classes/Exports: ImportExportScreen, _ImportExportScreenState, _ImportProgressDialog, _ImportProgressDialogState
- Key methods: _buildFeature, _buildFormatTable, _buildPreviewView, _buildProductDetail, _confirmImport, _copyToClipboard, _doImport, _exportProducts, _importProducts, _showErrorDialog, _showExportDialog, _showImportSummary, _showSnackBar, build, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../models/mall_product.dart';
import '../providers/mall_manager_provider.dart';
import '../services/csv_service.dart';
import '../services/file_download_service.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _isLoading = false;
  List<MallProduct> _importedProducts = [];
  List<String> _importErrors = [];
  bool _showPreview = false;

  Future<void> _exportProducts() async {
    final provider = context.read<MallManagerProvider>();
    final products = provider.products;

    if (products.isEmpty) {
      _showSnackBar('No products to export', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Generate CSV
      String csv = CsvService.exportProductsToCsv(products);

      // Create download filename
      final now = DateTime.now();
      final filename =
          'SwiftCart_Products_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}.csv';

      final downloaded = await downloadTextFile(
        filename: filename,
        content: csv,
        mimeType: 'text/csv;charset=utf-8',
      );
      if (downloaded) {
        _showSnackBar('CSV export started');
      } else {
        _showExportDialog(filename, csv, products.length);
      }
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showExportDialog(String filename, String csvContent, int productCount) {
```

## lib/screens/mall_billing_settings_screen.dart

- Type: Flutter/Dart
- Lines: 225
- Classes/Exports: MallBillingSettingsScreen, _MallBillingSettingsScreenState
- Key methods: _save, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mall_billing_settings.dart';
import '../providers/mall_manager_provider.dart';

class MallBillingSettingsScreen extends StatefulWidget {
  const MallBillingSettingsScreen({super.key});

  @override
  State<MallBillingSettingsScreen> createState() =>
      _MallBillingSettingsScreenState();
}

class _MallBillingSettingsScreenState extends State<MallBillingSettingsScreen> {
  late final TextEditingController _gstCtrl;
  late final TextEditingController _taxLabelCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _extraChargeLabelCtrl;
  late final TextEditingController _extraChargeCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<MallManagerProvider>().billingSettings;
    _gstCtrl = TextEditingController(
      text: settings.gstPercent == 0 ? '' : settings.gstPercent.toString(),
    );
    _taxLabelCtrl = TextEditingController(text: settings.taxLabel);
    _taxCtrl = TextEditingController(
      text: settings.taxPercent == 0 ? '' : settings.taxPercent.toString(),
    );
    _extraChargeLabelCtrl =
        TextEditingController(text: settings.extraChargeLabel);
    _extraChargeCtrl = TextEditingController(
      text: settings.extraChargeAmount == 0
          ? ''
          : settings.extraChargeAmount.toString(),
    );
  }

  @override
  void dispose() {
    _gstCtrl.dispose();
    _taxLabelCtrl.dispose();
    _taxCtrl.dispose();
    _extraChargeLabelCtrl.dispose();
    _extraChargeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<MallManagerProvider>().billingSettings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Settings'),
        elevation: 0,
```

## lib/screens/mall_details_screen.dart

- Type: Flutter/Dart
- Lines: 460
- Classes/Exports: MallDetailsScreen, _SectionCard, _DetailRow, _ManagerTile
- Key methods: _showAddManagerDialog, build

### Header Excerpt

```dart
// ignore_for_file: use_null_aware_elements

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mall_manager_account.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import 'mall_manager_details_screen.dart';
import 'manage_subscription_screen.dart';

class MallDetailsScreen extends StatelessWidget {
  final MallSubscription mall;

  const MallDetailsScreen({super.key, required this.mall});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mall.name), elevation: 0),
      body: StreamBuilder<List<MallManagerAccount>>(
        stream: context.read<AdminProvider>().watchMallManagers(mall.mallId),
        builder: (context, snapshot) {
          final managers = snapshot.data ?? const <MallManagerAccount>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Mall Details',
                child: Column(
                  children: [
                    _DetailRow(label: 'Mall ID', value: mall.mallId),
                    _DetailRow(label: 'Mall Name', value: mall.name),
                    _DetailRow(
                      label: 'Owner Name',
                      value: mall.ownerName?.trim().isNotEmpty == true
                          ? mall.ownerName!
                          : '-',
                    ),
                    _DetailRow(
                      label: 'Owner Email',
                      value: mall.ownerEmail?.trim().isNotEmpty == true
                          ? mall.ownerEmail!
                          : '-',
                    ),
                    _DetailRow(
                      label: 'Location',
                      value:
                          '${mall.city?.trim().isNotEmpty == true ? mall.city : '-'}, ${mall.state?.trim().isNotEmpty == true ? mall.state : '-'}',
                    ),
                    _DetailRow(
                      label: 'Created',
                      value: _formatDate(mall.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Subscription',
```

## lib/screens/mall_manager_details_screen.dart

- Type: Flutter/Dart
- Lines: 287
- Classes/Exports: MallManagerDetailsScreen, _InfoRow, _StatusChip
- Key methods: build

### Header Excerpt

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';

class MallManagerDetailsScreen extends StatelessWidget {
  final String mallId;
  final String managerId;

  const MallManagerDetailsScreen({
    super.key,
    required this.mallId,
    required this.managerId,
  });

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('malls')
        .doc(mallId)
        .collection('managers')
        .doc(managerId);

    return Scaffold(
      appBar: AppBar(title: Text('Manager • $managerId'), elevation: 0),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('Manager not found'));
          }

          final data = doc.data() ?? {};
          final assignedEmail = (data['assignedEmail'] ?? '').toString();
          final fullName = (data['fullName'] ?? '').toString();
          final phoneNumber = (data['phoneNumber'] ?? '').toString();
          final isActive = data['isActive'] == null
              ? true
              : data['isActive'] == true;
          final doj = data['dateOfJoining'];
          DateTime? joiningDate;
          if (doj is Timestamp) {
            joiningDate = doj.toDate();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 1,
                child: Padding(
```

## lib/screens/mall_manager_login_screen.dart

- Type: Flutter/Dart
- Lines: 222
- Classes/Exports: MallManagerLoginScreen, _MallManagerLoginScreenState
- Key methods: _login, build, dispose

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../app/app.dart';
import '../providers/mall_manager_provider.dart';
import '../widgets/swiftcart_logo.dart';
import 'products_management_screen.dart';
import 'web_mall_manager_dashboard_screen.dart';

class MallManagerLoginScreen extends StatefulWidget {
  const MallManagerLoginScreen({super.key});

  @override
  State<MallManagerLoginScreen> createState() => _MallManagerLoginScreenState();
}

class _MallManagerLoginScreenState extends State<MallManagerLoginScreen> {
  final _managerIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _managerIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final managerId = _managerIdCtrl.text.trim().toUpperCase();
    final password = _passwordCtrl.text;

    if (managerId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter Manager ID')));
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter Password')));
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<MallManagerProvider>();
    final success = await provider.loginAsMallManager(
      managerId: managerId,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
```

## lib/screens/mall_manager_profile_screen.dart

- Type: Flutter/Dart
- Lines: 181
- Classes/Exports: MallManagerProfileScreen, _MallManagerProfileScreenState
- Key methods: _formatDate, _pickJoiningDate, _save, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mall_manager_provider.dart';

class MallManagerProfileScreen extends StatefulWidget {
  const MallManagerProfileScreen({super.key});

  @override
  State<MallManagerProfileScreen> createState() =>
      _MallManagerProfileScreenState();
}

class _MallManagerProfileScreenState extends State<MallManagerProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  DateTime? _joiningDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MallManagerProvider>();
    final profile = provider.profile;

    _nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phoneNumber ?? '');
    _joiningDate = profile?.dateOfJoining;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MallManagerProvider>().loadManagerProfile();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MallManagerProvider>();
    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Profile'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
```

## lib/screens/mall_managers_screen.dart

- Type: Flutter/Dart
- Lines: 413
- Classes/Exports: MallManagersScreen, _StatusChip
- Key methods: _showAddManagerDialog, build

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mall_manager_account.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import 'mall_manager_details_screen.dart';

class MallManagersScreen extends StatelessWidget {
  final MallSubscription mall;

  const MallManagersScreen({super.key, required this.mall});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Managers • ${mall.name}'), elevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddManagerDialog(context),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.store_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mall.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mall ID: ${mall.mallId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
```

## lib/screens/mall_qr_library_screen.dart

- Type: Flutter/Dart
- Lines: 338
- Classes/Exports: MallQrLibraryScreen, _MallQrLibraryScreenState, _MallQrCard, _EmptyMallQrState
- Key methods: _copyMallId, _matchesSearch, _printAll, _printSingle, build, dispose

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import '../services/mall_qr_print_service.dart';

class MallQrLibraryScreen extends StatefulWidget {
  const MallQrLibraryScreen({super.key});

  @override
  State<MallQrLibraryScreen> createState() => _MallQrLibraryScreenState();
}

class _MallQrLibraryScreenState extends State<MallQrLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final malls = provider.malls.where(_matchesSearch).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mall QR Library'),
            actions: [
              IconButton(
                onPressed: malls.isEmpty ? null : () => _printAll(context, malls),
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Print all QR labels',
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                color: Colors.blueGrey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${malls.length} printable mall QR${malls.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
```

## lib/screens/mall_qr_scanner_screen.dart

- Type: Flutter/Dart
- Lines: 276
- Classes/Exports: MallQrScannerScreen, _MallQrScannerScreenState, _CornerBracketPainter
- Key methods: _buildCornerBracket, _onDetect, _switchCamera, _toggleTorch, _triggerScanFeedback, build, dispose, initState, paint, shouldRepaint

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class MallQrScannerScreen extends StatefulWidget {
  const MallQrScannerScreen({super.key});

  @override
  State<MallQrScannerScreen> createState() => _MallQrScannerScreenState();
}

class _MallQrScannerScreenState extends State<MallQrScannerScreen> {
  late MobileScannerController _controller;
  bool _handled = false;
  bool _isTorchOn = false;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _extractMallId(String raw) {
    final s = raw.trim();

    final direct = RegExp(r'^\d{8}[A-Za-z]{2}\d{2}$');
    if (direct.hasMatch(s)) return s.toUpperCase();

    final match = RegExp(r'(\d{8}[A-Za-z]{2}\d{2})').firstMatch(s);
    if (match != null) return match.group(1)!.toUpperCase();

    return null;
  }

  Future<void> _triggerScanFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 150);
      }
    } catch (_) {}

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !_isScanning) return;
```

## lib/screens/mall_select_screen.dart

- Type: Flutter/Dart
- Lines: 363
- Classes/Exports: MallSelectScreen, _MallSelectScreenState, _QuickChip
- Key methods: _continueWithMallId, _isValidMallId, _scanMallQr, _showLogoutDialog, build, dispose

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/user_auth_provider.dart';
import '../app/app.dart';
import '../widgets/swiftcart_logo.dart';
import 'scan_product_screen.dart';
import 'mall_qr_scanner_screen.dart';
import 'user_profile_screen.dart';

class MallSelectScreen extends StatefulWidget {
  const MallSelectScreen({super.key});

  @override
  State<MallSelectScreen> createState() => _MallSelectScreenState();
}

class _MallSelectScreenState extends State<MallSelectScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  bool _isValidMallId(String input) {
    final s = input.trim().toUpperCase();
    // 6 digits area + 2 digits mall + 2 letters + 2 digits year
    return RegExp(r'^\d{8}[A-Z]{2}\d{2}$').hasMatch(s);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continueWithMallId(String mallIdRaw) async {
    final mallId = mallIdRaw.trim().toUpperCase();

    if (!_isValidMallId(mallId)) {
      setState(() => _error = "Invalid Mall ID (Example: 11000103CP19)");
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('malls')
          .doc(mallId)
          .get();

      if (!doc.exists) {
        setState(() => _error = "Mall not found. Please check Mall ID.");
        return;
      }
```

## lib/screens/manage_subscription_screen.dart

- Type: Flutter/Dart
- Lines: 534
- Classes/Exports: ManageSubscriptionScreen, _ManageSubscriptionScreenState
- Key methods: _deactivateMall, _renew1Year, _renew3Months, _saveChanges, _selectEndDate, build, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';

class ManageSubscriptionScreen extends StatefulWidget {
  final MallSubscription mall;

  const ManageSubscriptionScreen({
    super.key,
    required this.mall,
  });

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  late DateTime _newEndDate;
  late String _selectedPlan;
  late bool _isActive;
  bool _isUpdating = false;

  final planDetails = {
    'basic': {'name': 'Basic', 'products': 1000, 'price': '₹999/month'},
    'pro': {'name': 'Pro', 'products': 5000, 'price': '₹2999/month'},
    'enterprise': {'name': 'Enterprise', 'products': 50000, 'price': 'Custom'},
  };

  @override
  void initState() {
    super.initState();
    _newEndDate = widget.mall.subscriptionEndDate;
    _selectedPlan = widget.mall.planType;
    _isActive = widget.mall.isActive;
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _newEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _newEndDate = picked);
    }
  }

  Future<void> _renew1Year() async {
    setState(() => _newEndDate = _newEndDate.add(const Duration(days: 365)));
  }

  Future<void> _renew3Months() async {
    setState(() => _newEndDate = _newEndDate.add(const Duration(days: 90)));
  }

  Future<void> _saveChanges() async {
    setState(() => _isUpdating = true);
```

## lib/screens/phone_otp_auth_screen.dart

- Type: Flutter/Dart
- Lines: 499
- Classes/Exports: PhoneOtpAuthScreen, _PhoneOtpAuthScreenState
- Key methods: _formatTime, _resendOtp, _sendOtp, _showSnack, _startResendCountdown, _verifyOtp, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_auth_provider.dart';
import 'mall_select_screen.dart';
import '../widgets/swiftcart_logo.dart';

class PhoneOtpAuthScreen extends StatefulWidget {
  const PhoneOtpAuthScreen({super.key});

  @override
  State<PhoneOtpAuthScreen> createState() => _PhoneOtpAuthScreenState();
}

class _PhoneOtpAuthScreenState extends State<PhoneOtpAuthScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _phoneController;
  late TextEditingController _otpController;
  late TextEditingController _nameController;
  
  int _step = 1; // 1: Phone, 2: OTP
  bool _isLoading = false;
  bool _isSignup = false;
  int _otpResendCountdown = 0;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _otpController = TextEditingController();
    _nameController = TextEditingController();
    _timerController =
        AnimationController(duration: const Duration(seconds: 120), vsync: this);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }

    if (!RegExp(r'^\+\d{10,15}$').hasMatch(phone)) {
      _showSnack('Please enter valid phone with country code (e.g., +919876543210)');
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<UserAuthProvider>();
    final success = await provider.sendCustomPhoneOtp(phone);
```

## lib/screens/product_search_screen.dart

- Type: Flutter/Dart
- Lines: 315
- Classes/Exports: ProductSearchScreen, _ProductSearchScreenState, _SearchProductCard
- Key methods: _sortProducts, build, dispose

### Header Excerpt

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/mall_product.dart';
import '../providers/cart_provider.dart';

class ProductSearchScreen extends StatefulWidget {
  final String mallId;

  const ProductSearchScreen({super.key, required this.mallId});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _inStockOnly = false;
  String _sortBy = 'name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsStream = FirebaseFirestore.instance
        .collection('malls')
        .doc(widget.mallId)
        .collection('products')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data?.docs
                  .map((doc) => MallProduct.fromMap(doc.data()))
                  .toList() ??
              <MallProduct>[];

          final categories = <String>{
            'All',
            ...products
                .map((product) => product.category.trim())
                .where((category) => category.isNotEmpty),
          }.toList()
```

## lib/screens/products_management_screen.dart

- Type: Flutter/Dart
- Lines: 1586
- Classes/Exports: ProductsManagementScreen, _ProductsManagementScreenState, _TopToolbar, _FilterBar, _SummaryCard, _ProductsTable, _EmptyProductState, _BillingSettingsDialog, _BillingSettingsDialogState, _ProductCard, _MetricChip, _AddProductDialog, _AddProductDialogState
- Key methods: _deleteProduct, _filteredProducts, _generateBarcode, _logout, _openBarcodeLibrary, _printBarcode, _save, _showAddProductDialog, _showBarcodePreview, _showBillingSettingsDialog, _submit, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../models/mall_billing_settings.dart';
import '../models/mall_product.dart';
import '../providers/mall_manager_provider.dart';
import '../screens/barcode_library_screen.dart';
import '../screens/import_export_screen.dart';
import '../services/barcode_print_service.dart';
import '../services/barcode_service.dart';
import '../widgets/product_barcode_widget.dart';

class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  State<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _stockFilter = 'All';
  String _sortBy = 'Name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        final provider = context.read<MallManagerProvider>();
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Manager Portal'),
            content: const Text(
              'Do you want to logout and go back to the home screen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
```

## lib/screens/sales_history_screen.dart

- Type: Flutter/Dart
- Lines: 1199
- Classes/Exports: SalesHistoryScreen, _SalesHistoryScreenState, _HeroHeader, _FilterBar, _PaymentsTable, _Pill, _StatusPill, _Card, _Metric, _ConsolidatedSummaryCard, _SummaryRow, _TrendBucketsCard, _Bucket, _BucketAccumulator
- Key methods: _bucketKey, _bucketLabel, _buildBuckets, _currency, _exportCsv, _fmt, _matchesFilters, _monthLabel, _pickCustomRange, build, dispose

### Header Excerpt

```dart
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mall_manager_provider.dart';
import '../services/file_download_service.dart';

enum _SalesPreset { today, last7, last30, thisMonth, thisYear, custom, all }

enum _GroupBy { day, week, month, year }

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  static const _monthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _searchCtrl = TextEditingController();
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  _SalesPreset _preset = _SalesPreset.last7;
  _GroupBy _groupBy = _GroupBy.day;
  DateTimeRange? _customRange;
  String _method = 'All';
  String _status = 'All';
  int _limit = 500;
  int _refreshNonce = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MallManagerProvider>();
```

## lib/screens/scan_product_screen.dart

- Type: Flutter/Dart
- Lines: 909
- Classes/Exports: ScanProductScreen, _ScanProductScreenState
- Key methods: _addToCart, _buildBarcodeInputSection, _buildBrowseButton, _buildCartIconButton, _buildDetailColumn, _buildDivider, _buildFindProductButton, _buildIconButton, _buildMessageWidget, _buildModernAppBar, _buildProductCard, _findProduct, _scanBarcode, _toInt, build, dispose

### Header Excerpt

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'barcode_scanner_screen.dart';
import 'product_search_screen.dart';

class ScanProductScreen extends StatefulWidget {
  final String mallId;
  const ScanProductScreen({super.key, required this.mallId});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  final _barcodeCtrl = TextEditingController();
  bool _loading = false;

  Map<String, dynamic>? _product;
  String? _message;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (scanned == null) return;

    _barcodeCtrl.text = scanned;
    await _findProduct();
  }

  Future<void> _findProduct() async {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) {
      setState(() {
        _message = "Enter a barcode";
        _product = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _product = null;
    });

    try {
```

## lib/screens/user_auth_screen.dart

- Type: Flutter/Dart
- Lines: 760
- Classes/Exports: UserAuthGateScreen, UserAuthScreen, _UserAuthScreenState, _ForgotPasswordDialog, _ForgotPasswordDialogState
- Key methods: _buildEmailTab, _buildPhoneTab, _getActionButtonLabel, _getStepTitle, _handleEmailAuth, _resendOtp, _sendOtp, _showForgotPasswordDialog, _showMessage, _showSnack, _startResendCountdown, _verifyAndReset, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../providers/user_auth_provider.dart';
import 'mall_select_screen.dart';
import 'email_verification_pending_screen.dart';
import 'phone_otp_auth_screen.dart';
import '../widgets/swiftcart_logo.dart';

class UserAuthGateScreen extends StatelessWidget {
  const UserAuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserAuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.canEnterApp) {
          return const MallSelectScreen();
        }
        if (authProvider.needsEmailVerification) {
          return EmailVerificationPendingScreen(
            email: authProvider.currentUser?.email ?? '',
          );
        }
        return const UserAuthScreen();
      },
    );
  }
}

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({super.key});

  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _emailNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isEmailLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailNameController.dispose();
    _emailController.dispose();
```

## lib/screens/user_profile_screen.dart

- Type: Flutter/Dart
- Lines: 773
- Classes/Exports: UserProfileScreen, _PersonalInfoTab, _BillsTab, _PaymentsTab, _InfoCard, _StatusChip, _SectionTitle, _ProfileAvatar, _AvatarPreset
- Key methods: _setAvatarPreset, _showEditDialog, _updateProfilePicture, build

### Header Excerpt

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'dart:io';

import '../providers/user_auth_provider.dart';
import '../services/history_print_service.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<UserAuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: false,
          backgroundColor: const Color(0xFFF4EFFD),
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Personal Info'),
              Tab(text: 'Previous Bills'),
              Tab(text: 'Payment History'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4EFFD), Color(0xFFF9F7FF), Color(0xFFFFFFFF)],
            ),
          ),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userDoc.snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? <String, dynamic>{};
              final fullName =
                  (data['fullName'] ?? user.displayName ?? 'Cartiqo User')
                      .toString();
              final email = (data['email'] ?? user.email ?? '').toString();
              final phone = (data['phone'] ?? user.phoneNumber ?? '').toString();
```

## lib/screens/web_admin_dashboard_screen.dart

- Type: Flutter/Dart
- Lines: 1348
- Classes/Exports: WebAdminDashboardScreen, _WebAdminDashboardScreenState, _AdminSidebar, _AdminHeader, _DirectoryPanel, _DirectoryPanelState, _GridHint, _PlanBadge, _HealthBadge, _ActivityPanel, _SubscriptionHealthPanel, _AnnouncementsPanel, _SupportPanel, _ReportsPanel, _ActionStrip, _ActionData, _SideTile, _StatCard, _Panel, _MiniRow, _AnnouncementDialog, _AnnouncementDialogState
- Key methods: _exportMallReport, _submit, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import '../services/csv_service.dart';
import '../services/file_download_service.dart';
import '../widgets/swiftcart_logo.dart';
import 'add_mall_screen.dart';
import 'mall_details_screen.dart';
import 'mall_managers_screen.dart';
import 'mall_qr_library_screen.dart';
import 'manage_subscription_screen.dart';

class WebAdminDashboardScreen extends StatefulWidget {
  const WebAdminDashboardScreen({super.key});

  @override
  State<WebAdminDashboardScreen> createState() =>
      _WebAdminDashboardScreenState();
}

class _WebAdminDashboardScreenState extends State<WebAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().refreshMalls();
    });
  }

  Future<void> _exportMallReport(
    BuildContext context,
    AdminProvider provider,
  ) async {
    final malls = provider.malls;
    if (malls.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No mall data to export')));
      return;
    }

    final managerCounts = await provider.getMallManagerCounts(
      malls.map((mall) => mall.mallId).toList(),
    );
    final csv = CsvService.exportMallSubscriptionsToCsv(malls, managerCounts);
    final now = DateTime.now();
    final filename =
        'cartiqo_mall_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

    final ok = await downloadTextFile(
      filename: filename,
      content: csv,
      mimeType: 'text/csv;charset=utf-8',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
```

## lib/screens/web_mall_manager_dashboard_screen.dart

- Type: Flutter/Dart
- Lines: 1376
- Classes/Exports: WebMallManagerDashboardScreen, _ManagerSidebar, _ManagerHeader, _InventoryPanel, _InventoryPanelState, _GridHint, _StockBadge, _AlertsPanel, _BillingPreviewPanel, _TopProductsPanel, _TransactionsPanel, _PromotionsPanel, _SearchPanel, _StaffActivityPanel, _ActionRow, _ActionItem, _MenuTile, _ManagerStatCard, _Panel, _MiniCard, _PromotionDialog, _PromotionDialogState
- Key methods: _submit, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app.dart';
import '../models/mall_product.dart';
import '../providers/mall_manager_provider.dart';
import '../widgets/swiftcart_logo.dart';
import '../widgets/manager_sales_dashboard_panel.dart';
import 'barcode_library_screen.dart';
import 'import_export_screen.dart';
import 'mall_billing_settings_screen.dart';
import 'mall_manager_profile_screen.dart';
import 'products_management_screen.dart';
import 'sales_history_screen.dart';

class WebMallManagerDashboardScreen extends StatelessWidget {
  const WebMallManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MallManagerProvider>(
      builder: (context, provider, _) {
        final products = provider.products;
        final wide = MediaQuery.of(context).size.width >= 1180;
        final inStock = products.where((product) => product.inStock).length;
        final lowStock = products.where((product) => product.isLowStock).length;
        final outOfStock = products
            .where((product) => !product.inStock || product.stock <= 0)
            .length;
        final topProducts = [...products]
          ..sort((a, b) => b.price.compareTo(a.price));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FC),
          drawer: wide
              ? null
              : Drawer(
                  child: _ManagerSidebar(
                    compact: true,
                    mallId: provider.currentMallId ?? 'Mall Manager',
                    onOpenSales: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SalesHistoryScreen(),
                      ),
                    ),
                    onOpenProfile: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallManagerProfileScreen(),
                      ),
                    ),
                    onOpenProducts: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProductsManagementScreen(),
                      ),
                    ),
                    onOpenBillingSettings: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MallBillingSettingsScreen(),
                      ),
                    ),
```

## lib/screens/web_portal_home_screen.dart

- Type: Flutter/Dart
- Lines: 1310
- Classes/Exports: WebPortalHomeScreen, _TopBar, _HeroSection, _PortalSection, _DemoSection, _PricingSection, _CtaSection, _SectionShell, _AdaptiveList, _PortalCard, _DarkPanel, _DarkPanelItem, _InfoCard, _PlanCard, _PreviewRow, _BillLine, _Pill, _FooterSection, _SupportRequestDialog, _SupportRequestDialogState
- Key methods: _submit, build, dispose

### Header Excerpt

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/swiftcart_logo.dart';
import 'admin_login_screen.dart';
import 'mall_manager_login_screen.dart';

class WebPortalHomeScreen extends StatelessWidget {
  const WebPortalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FBFF), Color(0xFFEEF4FF), Color(0xFFFFF7EE)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 1180
                  ? 1180.0
                  : constraints.maxWidth;
              final isWide = width >= 960;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(isWide: isWide),
                        const SizedBox(height: 18),
                        _HeroSection(isWide: isWide),
                        const SizedBox(height: 18),
                        _PortalSection(isWide: isWide),
                        const SizedBox(height: 18),
                        _SectionShell(
                          title: 'How It Works',
                          subtitle:
                              'Show the scan-to-bill journey clearly on the website.',
                          child: _AdaptiveList(
                            isWide: isWide,
                            children: const [
                              _InfoCard(
                                icon: Icons.qr_code_scanner_outlined,
                                title: 'Scan products',
                                subtitle:
                                    'Identify items fast with barcode-first checkout.',
                              ),
                              _InfoCard(
                                icon: Icons.receipt_long_outlined,
                                title: 'Build the bill',
                                subtitle:
```

## lib/screens/web_portal_home_screen_stub.dart

- Type: Flutter/Dart
- Lines: 13
- Classes/Exports: WebPortalHomeScreen
- Key methods: build

### Header Excerpt

```dart
import 'package:flutter/material.dart';

import 'user_auth_screen.dart';

class WebPortalHomeScreen extends StatelessWidget {
  const WebPortalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserAuthGateScreen();
  }
}
```

## lib/services/

## lib/services/barcode_print_service.dart

- Type: Flutter/Dart
- Lines: 239
- Classes/Exports: BarcodeLabelData, BarcodePrintOptions, BarcodePrintService
- Key methods: (n/a)

### Header Excerpt

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/mall_product.dart';

class BarcodeLabelData {
  final String productName;
  final String barcode;
  final String brand;
  final String unit;
  final double price;

  const BarcodeLabelData({
    required this.productName,
    required this.barcode,
    required this.brand,
    required this.unit,
    required this.price,
  });

  factory BarcodeLabelData.fromProduct(MallProduct product) {
    return BarcodeLabelData(
      productName: product.name,
      barcode: product.barcode,
      brand: product.brand,
      unit: product.unit,
      price: product.price,
    );
  }
}

enum BarcodeLabelSize { compact, standard, detailed }

class BarcodePrintOptions {
  final BarcodeLabelSize size;
  final bool showPrice;
  final bool showBrand;
  final bool showUnit;

  const BarcodePrintOptions({
    this.size = BarcodeLabelSize.standard,
    this.showPrice = true,
    this.showBrand = true,
    this.showUnit = true,
  });
}

class BarcodePrintService {
  const BarcodePrintService._();

  static Future<void> printSingleLabel(
    BarcodeLabelData label, {
    BarcodePrintOptions options = const BarcodePrintOptions(),
  }) {
    return _printLabels(
      [label],
      jobName: 'Barcode_${label.barcode}',
      options: options,
    );
```

## lib/services/barcode_service.dart

- Type: Flutter/Dart
- Lines: 72
- Classes/Exports: BarcodeService
- Key methods: (n/a)

### Header Excerpt

```dart
import 'dart:math';

class BarcodeService {
  static final Random _random = Random();

  /// Generate a random 13-digit barcode number (EAN-13 format)
  /// Format: XXXXXXXXXXXXX (13 digits)
  static String generateRandomBarcode({String? prefix}) {
    // Generate 12 random digits for the base barcode
    // Starting with timestamp for uniqueness, then random digits
    final now = DateTime.now();
    final year = now.year.toString().substring(2); // Last 2 digits of year
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random1 = _random.nextInt(100).toString().padLeft(2, '0');
    final random2 = _random.nextInt(10000).toString().padLeft(4, '0');
    
    // Create 12-digit base: YYMMDD(6) + RANDOM1(2) + RANDOM2(4)
    final baseBarcode = year + month + day + random1 + random2;
    
    print('DEBUG: Generated base barcode: $baseBarcode (length: ${baseBarcode.length})');
    
    // Calculate EAN-13 checksum
    final checksum = _calculateEAN13Checksum(baseBarcode);
    
    final barcode = baseBarcode + checksum;
    print('DEBUG: Final barcode: $barcode (length: ${barcode.length})');
    
    return barcode;
  }

  /// Generate a barcode with custom prefix (useful for mall-specific barcodes)
  static String generateBarcodeWithPrefix(String mallId) {
    // Use mall ID prefix (first 4 chars) + timestamp + random
    final prefix = mallId.substring(0, min(4, mallId.length)).toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(1000).toString().padLeft(3, '0');
    
    // Create barcode: PREFIX(2) + TIMESTAMP(6) + RANDOM(3) + CHECKSUM(1) = 12-13 digits
    final baseBarcode = prefix.substring(0, 2) + timestamp.toString().substring(4, 10) + randomPart;
    final checksum = _calculateEAN13Checksum(baseBarcode);
    
    return baseBarcode + checksum;
  }

  /// Calculate EAN-13 checksum digit
  static String _calculateEAN13Checksum(String barcode) {
    // For simplicity, use a mathematical approach
    int sum = 0;
    for (int i = 0; i < barcode.length; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    int checksum = (10 - (sum % 10)) % 10;
    return checksum.toString();
  }

  /// Validate if a barcode has valid format
  static bool isValidBarcode(String barcode) {
    return barcode.isNotEmpty && barcode.length >= 8 && RegExp(r'^\d+$').hasMatch(barcode);
```

## lib/services/csv_service.dart

- Type: Flutter/Dart
- Lines: 419
- Classes/Exports: CsvService, CsvImportResult
- Key methods: (n/a)

### Header Excerpt

```dart
import 'package:csv/csv.dart';
import '../models/mall_product.dart';
import '../models/mall_subscription.dart';

class CsvService {
  /// Export products to CSV format
  static String exportProductsToCsv(List<MallProduct> products) {
    List<List<dynamic>> rows = [
      [
        'Product Name',
        'Barcode',
        'Price',
        'Unit',
        'Brand',
        'Category',
        'Stock',
        'Weight',
        'Weight Unit',
        'In Stock',
      ],
    ];

    for (var product in products) {
      rows.add([
        product.name,
        product.barcode,
        product.price.toString(),
        product.unit,
        product.brand,
        product.category,
        product.stock.toString(),
        product.weight.toString(),
        product.weightUnit,
        product.inStock ? 'Yes' : 'No',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    return csv;
  }

  static String exportMallSubscriptionsToCsv(
    List<MallSubscription> malls,
    Map<String, int> managerCounts,
  ) {
    final rows = <List<dynamic>>[
      [
        'Mall Name',
        'Mall ID',
        'Owner Name',
        'Owner Email',
        'City',
        'State',
        'Plan',
        'Max Products',
        'Active',
        'Subscription Start',
        'Subscription End',
        'Expired',
        'Days Until Expiry',
```

## lib/services/file_download_service.dart

- Type: Flutter/Dart
- Lines: 3
- Classes/Exports: (none detected)
- Key methods: (n/a)

### Header Excerpt

```dart
export 'file_download_service_stub.dart'
    if (dart.library.html) 'file_download_service_web.dart';
```

## lib/services/file_download_service_stub.dart

- Type: Flutter/Dart
- Lines: 8
- Classes/Exports: (none detected)
- Key methods: downloadTextFile

### Header Excerpt

```dart
Future<bool> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'text/plain;charset=utf-8',
}) async {
  return false;
}
```

## lib/services/file_download_service_web.dart

- Type: Flutter/Dart
- Lines: 24
- Classes/Exports: (none detected)
- Key methods: downloadTextFile

### Header Excerpt

```dart
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

Future<bool> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'text/plain;charset=utf-8',
}) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return true;
}
```

## lib/services/history_print_service.dart

- Type: Flutter/Dart
- Lines: 306
- Classes/Exports: HistoryPrintService
- Key methods: (n/a)

### Header Excerpt

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HistoryPrintService {
  const HistoryPrintService._();

  static Future<void> printBill({
    required Map<String, dynamic> bill,
    required String customerName,
  }) async {
    final document = pw.Document();
    final items = _normalizedItems(bill['items']);
    final subtotal = _asNum(bill['subtotal']) ?? _sumLineTotals(items);
    final extraCharge = _asNum(bill['extraCharge']) ?? _asNum(bill['handlingFee']) ?? 0;
    final extraChargeLabel =
        (bill['extraChargeLabel'] ?? 'Extra Charges').toString();
    final gst = _asNum(bill['gst']) ?? 0;
    final gstPercent = _asNum(bill['gstPercent']) ?? 0;
    final otherTax = _asNum(bill['otherTax']) ?? 0;
    final otherTaxLabel = (bill['otherTaxLabel'] ?? 'Tax').toString();
    final otherTaxPercent = _asNum(bill['otherTaxPercent']) ?? 0;
    final total = _asNum(bill['total']) ?? (subtotal + extraCharge + gst + otherTax);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Cartiqo Mart Bill',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Bill No: ${(bill['billNumber'] ?? bill['billId'] ?? '').toString()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Mall ID: ${(bill['mallId'] ?? '').toString()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 8),
            _metaRow('Customer', customerName),
            _metaRow('Date', _formatDateTime(bill['createdAt'])),
            _metaRow('Status', (bill['status'] ?? 'paid').toString().toUpperCase()),
            pw.Divider(),
            ...items.map((item) => _billItemRow(item)),
            pw.Divider(),
```

## lib/services/mall_qr_print_service.dart

- Type: Flutter/Dart
- Lines: 128
- Classes/Exports: MallQrLabelData, MallQrPrintService
- Key methods: (n/a)

### Header Excerpt

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/mall_subscription.dart';

class MallQrLabelData {
  final String mallName;
  final String mallId;
  final String city;
  final String state;

  const MallQrLabelData({
    required this.mallName,
    required this.mallId,
    required this.city,
    required this.state,
  });

  factory MallQrLabelData.fromMall(MallSubscription mall) {
    return MallQrLabelData(
      mallName: mall.name,
      mallId: mall.mallId,
      city: mall.city ?? 'Unknown City',
      state: mall.state ?? 'Unknown State',
    );
  }
}

class MallQrPrintService {
  const MallQrPrintService._();

  static Future<void> printSingleLabel(MallQrLabelData label) {
    return _printLabels([label], jobName: 'Mall_QR_${label.mallId}');
  }

  static Future<void> printLabelSheet(List<MallQrLabelData> labels) {
    return _printLabels(labels, jobName: 'Mall_QR_Sheet');
  }

  static Future<void> _printLabels(
    List<MallQrLabelData> labels, {
    required String jobName,
  }) async {
    if (labels.isEmpty) {
      return;
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: labels.map(_buildLabelCard).toList(),
            ),
```

## lib/services/page_transitions.dart

- Type: Flutter/Dart
- Lines: 72
- Classes/Exports: SlidePageTransition, FadePageTransition, RotatePageTransition
- Key methods: (n/a)

### Header Excerpt

```dart
import 'package:flutter/material.dart';

class SlidePageTransition extends PageRouteBuilder {
  final Widget page;

  SlidePageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

class FadePageTransition extends PageRouteBuilder {
  final Widget page;

  FadePageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class RotatePageTransition extends PageRouteBuilder {
  final Widget page;

  RotatePageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
```

## lib/widgets/

## lib/widgets/animated_button.dart

- Type: Flutter/Dart
- Lines: 107
- Classes/Exports: AnimatedButton, _AnimatedButtonState
- Key methods: _onTapCancel, _onTapDown, _onTapUp, build, dispose, initState

### Header Excerpt

```dart
import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const AnimatedButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.isLoading = false,
    this.width,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (!widget.isLoading) {
      widget.onPressed();
    }
  }
```

## lib/widgets/manager_sales_dashboard_panel.dart

- Type: Flutter/Dart
- Lines: 971
- Classes/Exports: ManagerSalesDashboardPanel, _ManagerSalesDashboardPanelState, _SalesMetricCard, _AnalysisChip, _HintChip, _SalesSummary, _GroupedSalesAccumulator, _GroupedSalesRow
- Key methods: _buildAnalysisChips, _buildControls, _buildGroupedRows, _buildMetricGrid, _buildTableArea, _exportCsv, _formatCurrency, _formatDate, _groupDisplayLabel, _groupKey, _groupLabel, _isSameDay, _matchesMethodAndStatus, _matchesSelectedPeriod, _periodLabel, build, dispose, initState

### Header Excerpt

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../providers/mall_manager_provider.dart';
import '../services/csv_service.dart';
import '../services/file_download_service.dart';

enum _SalesPeriodPreset { all, today, week, month, year, custom }

enum _SalesGroupBy { day, week, month, year }

class ManagerSalesDashboardPanel extends StatefulWidget {
  final MallManagerProvider provider;

  const ManagerSalesDashboardPanel({super.key, required this.provider});

  @override
  State<ManagerSalesDashboardPanel> createState() =>
      _ManagerSalesDashboardPanelState();
}

class _ManagerSalesDashboardPanelState
    extends State<ManagerSalesDashboardPanel> {
  static const _monthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  _SalesPeriodPreset _periodPreset = _SalesPeriodPreset.all;
  _SalesGroupBy _groupBy = _SalesGroupBy.day;
  String _methodFilter = 'All';
  String _statusFilter = 'All';
  DateTimeRange? _customRange;
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }
```

## lib/widgets/product_barcode_widget.dart

- Type: Flutter/Dart
- Lines: 198
- Classes/Exports: ProductBarcodeWidget, _Ean13BarcodePainter
- Key methods: _buildPattern, _formatForDisplay, build, paint, shouldRepaint

### Header Excerpt

```dart
import 'package:flutter/material.dart';

class ProductBarcodeWidget extends StatelessWidget {
  final String barcode;
  final double height;
  final bool showText;

  const ProductBarcodeWidget({
    super.key,
    required this.barcode,
    this.height = 120,
    this.showText = true,
  });

  bool get _isEan13 => RegExp(r'^\d{13}$').hasMatch(barcode);

  @override
  Widget build(BuildContext context) {
    if (!_isEan13) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_stream, size: 36),
            const SizedBox(height: 8),
            Text(
              barcode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Barcode preview is available for 13-digit EAN codes.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _Ean13BarcodePainter(barcode),
            child: const SizedBox.expand(),
```

## lib/widgets/swiftcart_logo.dart

- Type: Flutter/Dart
- Lines: 158
- Classes/Exports: SwiftCartLogo, _SwiftCartLogoPainter
- Key methods: build, paint, shouldRepaint

### Header Excerpt

```dart
import 'package:flutter/material.dart';

class SwiftCartLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? backgroundColor;
  final Color? wordmarkColor;

  const SwiftCartLogo({
    super.key,
    this.size = 88,
    this.showWordmark = true,
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
    this.wordmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF0B5ED7);
    final accent = accentColor ?? const Color(0xFF12B886);
    final background = backgroundColor ?? Colors.white;
    final textColor = wordmarkColor ?? Colors.white;

    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwiftCartLogoPainter(
          primary: primary,
          accent: accent,
          background: background,
        ),
      ),
    );

    if (!showWordmark) {
      return mark;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.18),
        Text(
          'Cartiqo',
          style: TextStyle(
            fontSize: size * 0.30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: textColor,
          ),
        ),
      ],
    );
  }
```

## lib/models/

## lib/models/admin.dart

- Type: Flutter/Dart
- Lines: 50
- Classes/Exports: Admin
- Key methods: toMap

### Header Excerpt

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String adminId;
  final String email;
  final String name;
  final String role; // 'super_admin' or 'admin'
  final DateTime createdAt;

  Admin({
    required this.adminId,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt,
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    DateTime parseCreatedAt() {
      final value = map['createdAt'];
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return Admin(
      adminId: map['adminId'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'admin',
      createdAt: parseCreatedAt(),
    );
  }
}
```

## lib/models/cart_item.dart

- Type: Flutter/Dart
- Lines: 20
- Classes/Exports: CartItem
- Key methods: (n/a)

### Header Excerpt

```dart
class CartItem {
  final String productId;
  final String name;
  final String barcode;
  final int price; // rupees
  final String unit;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.price,
    required this.unit,
    this.qty = 1,
  });

  int get lineTotal => price * qty;
}
```

## lib/models/mall_billing_settings.dart

- Type: Flutter/Dart
- Lines: 51
- Classes/Exports: MallBillingSettings
- Key methods: toMap

### Header Excerpt

```dart
class MallBillingSettings {
  final double gstPercent;
  final String taxLabel;
  final double taxPercent;
  final String extraChargeLabel;
  final double extraChargeAmount;

  const MallBillingSettings({
    this.gstPercent = 0,
    this.taxLabel = 'Tax',
    this.taxPercent = 0,
    this.extraChargeLabel = 'Extra Charges',
    this.extraChargeAmount = 0,
  });

  bool get hasGst => gstPercent > 0;
  bool get hasTax => taxPercent > 0;
  bool get hasExtraCharge => extraChargeAmount > 0;

  Map<String, dynamic> toMap() {
    return {
      'gstPercent': gstPercent,
      'taxLabel': taxLabel,
      'taxPercent': taxPercent,
      'extraChargeLabel': extraChargeLabel,
      'extraChargeAmount': extraChargeAmount,
    };
  }

  factory MallBillingSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const MallBillingSettings();
    }

    return MallBillingSettings(
      gstPercent: _toDouble(map['gstPercent']),
      taxLabel: (map['taxLabel'] ?? 'Tax').toString(),
      taxPercent: _toDouble(map['taxPercent']),
      extraChargeLabel: (map['extraChargeLabel'] ?? 'Extra Charges').toString(),
      extraChargeAmount: _toDouble(map['extraChargeAmount']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
```

## lib/models/mall_manager_account.dart

- Type: Flutter/Dart
- Lines: 37
- Classes/Exports: MallManagerAccount
- Key methods: toMap

### Header Excerpt

```dart
class MallManagerAccount {
  final String mallId;
  final String managerId;
  final String? assignedUid;
  final String? assignedEmail;
  final bool isActive;

  MallManagerAccount({
    required this.mallId,
    required this.managerId,
    required this.assignedUid,
    required this.assignedEmail,
    required this.isActive,
  });

  factory MallManagerAccount.fromMap(String mallId, Map<String, dynamic> map) {
    return MallManagerAccount(
      mallId: mallId,
      managerId: (map['managerId'] ?? '').toString(),
      assignedUid: map['assignedUid'] == null ? null : map['assignedUid'].toString(),
      assignedEmail:
          map['assignedEmail'] == null ? null : map['assignedEmail'].toString(),
      isActive: map['isActive'] == null ? true : map['isActive'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mallId': mallId,
      'managerId': managerId,
      'assignedUid': assignedUid,
      'assignedEmail': assignedEmail,
      'isActive': isActive,
    };
  }
}
```

## lib/models/mall_manager_profile.dart

- Type: Flutter/Dart
- Lines: 70
- Classes/Exports: MallManagerProfile
- Key methods: toUpdateMap

### Header Excerpt

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MallManagerProfile {
  final String mallId;
  final String managerId;
  final String email;
  final String fullName;
  final String phoneNumber;
  final DateTime? dateOfJoining;

  const MallManagerProfile({
    required this.mallId,
    required this.managerId,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.dateOfJoining,
  });

  MallManagerProfile copyWith({
    String? email,
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfJoining,
  }) {
    return MallManagerProfile(
      mallId: mallId,
      managerId: managerId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  factory MallManagerProfile.fromManagerDoc({
    required String mallId,
    required String managerId,
    required Map<String, dynamic> data,
  }) {
    return MallManagerProfile(
      mallId: mallId,
      managerId: managerId,
      email: (data['assignedEmail'] ?? '').toString(),
      fullName: (data['fullName'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      dateOfJoining: _readDate(data['dateOfJoining']),
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'fullName': fullName,
```

## lib/models/mall_product.dart

- Type: Flutter/Dart
- Lines: 62
- Classes/Exports: MallProduct
- Key methods: toMap

### Header Excerpt

```dart
class MallProduct {
  final String productId;
  final String name;
  final String barcode;
  final double price;
  final double weight;
  final String weightUnit; // 'mg', 'g', 'kg', 'ml', 'l'
  final String unit;
  final String brand;
  final String category;
  final int stock;
  final bool inStock;

  MallProduct({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.price,
    required this.weight,
    this.weightUnit = 'g',
    this.unit = '1 pc',
    this.brand = 'General',
    this.category = 'General',
    this.stock = 0,
    this.inStock = true,
  });

  bool get isLowStock => stock <= 5;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'barcode': barcode,
      'price': price,
      'weight': weight,
      'weightUnit': weightUnit,
      'unit': unit,
      'brand': brand,
      'category': category,
      'stock': stock,
      'inStock': inStock,
    };
  }

  factory MallProduct.fromMap(Map<String, dynamic> map) {
    return MallProduct(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      weight: (map['weight'] ?? 0.0).toDouble(),
      weightUnit: map['weightUnit'] ?? 'g',
      unit: map['unit'] ?? '1 pc',
      brand: map['brand'] ?? 'General',
      category: map['category'] ?? 'General',
      stock: map['stock'] ?? 0,
      inStock: map['inStock'] ?? true,
    );
  }
```

## lib/models/mall_subscription.dart

- Type: Flutter/Dart
- Lines: 103
- Classes/Exports: MallSubscription
- Key methods: toMap

### Header Excerpt

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MallSubscription {
  final String mallId;
  final String name; // Mall name (matches your 'name' field)
  final String? ownerName;
  final String? ownerEmail;
  final String? city;
  final String? state;
  final DateTime subscriptionStartDate;
  final DateTime subscriptionEndDate;
  final String planType; // 'basic', 'pro', 'enterprise'
  final int maxProducts;
  final bool isActive;
  final DateTime createdAt;
  
  // Your existing fields
  final String? areaCode;
  final int? estYear;
  final String? mallCode;
  final int? mallNumber;
  final bool? active;

  MallSubscription({
    required this.mallId,
    required this.name,
    this.ownerName,
    this.ownerEmail,
    this.city,
    this.state,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
    required this.planType,
    required this.maxProducts,
    required this.isActive,
    required this.createdAt,
    this.areaCode,
    this.estYear,
    this.mallCode,
    this.mallNumber,
    this.active,
  });

  bool get isExpired => subscriptionEndDate.isBefore(DateTime.now());
  int get daysUntilExpiry =>
      subscriptionEndDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'mallId': mallId,
      'name': name,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'city': city,
      'state': state,
      'subscriptionStartDate': subscriptionStartDate,
      'subscriptionEndDate': subscriptionEndDate,
      'planType': planType,
      'maxProducts': maxProducts,
      'isActive': isActive,
```

## functions/src/

## functions/src/index.ts

- Type: Firebase Cloud Functions (TypeScript)
- Lines: 586
- Classes/Exports: sendPhoneOtp, cleanupExpiredOtps, verifyOtpManual, logOtpEvent, sendEmailOtpSignup, sendPasswordResetOtp, cleanupExpiredEmailOtps
- Key methods: (n/a)

### Header Excerpt

```ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import twilio from 'twilio';
import { existsSync, readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Initialize Firebase Admin
admin.initializeApp();

function loadLocalEnv(): void {
  const currentDir = path.dirname(fileURLToPath(import.meta.url));
  const envPath = path.join(currentDir, '..', '.env');

  if (!existsSync(envPath)) {
    return;
  }

  const envFile = readFileSync(envPath, 'utf8');
  for (const rawLine of envFile.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) {
      continue;
    }

    const separatorIndex = line.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

loadLocalEnv();

function getRequiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(
      `Missing ${name}. Set it in functions/.env for local deploys or use Firebase Functions secrets for production.`
    );
  }
  return value;
}

function getTwilioClient() {
  const accountSid = getRequiredEnv('TWILIO_ACCOUNT_SID');
```

