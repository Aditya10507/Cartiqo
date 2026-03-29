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

  int _ean13CheckDigit(String base12Digits) {
    // EAN-13 check digit for 12-digit base:
    // Sum of digits in odd positions + 3 * sum of digits in even positions.
    int sum = 0;
    for (int i = 0; i < base12Digits.length; i++) {
      final digit = int.tryParse(base12Digits[i]) ?? 0;
      sum += digit * (i.isEven ? 1 : 3);
    }
    final mod = sum % 10;
    return mod == 0 ? 0 : (10 - mod);
  }

  Future<String> _allocateAutoBarcodeEan13() async {
    final mallId = _currentMallId;
    if (mallId == null) {
      throw StateError('No mall selected');
    }

    // Generate mall-scoped, unique EAN-13 codes using a counter stored on the
    // mall document. We use a fixed '2' prefix to avoid collisions with legacy
    // barcode formats already in use.
    final mallRef = _firestore.collection('malls').doc(mallId);

    return _firestore.runTransaction((txn) async {
      final snap = await txn.get(mallRef);
      final data = snap.data() ?? <String, dynamic>{};
      final current = (data['barcodeCounter'] as num?)?.toInt() ?? 1;
      txn.set(mallRef, {'barcodeCounter': current + 1}, SetOptions(merge: true));

      final base = '2${current.toString().padLeft(11, '0')}'; // 12 digits
      final check = _ean13CheckDigit(base);
      return '$base$check';
    });
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
        .collection('malls')
        .doc(_currentMallId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchPromotions() {
    if (_currentMallId == null) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('malls')
        .doc(_currentMallId)
        .collection('promotions')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchStaffActivity() {
    if (_currentMallId == null) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('malls')
        .doc(_currentMallId)
        .collection('staff_activity')
        .orderBy('createdAt', descending: true)
        .limit(12)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(6)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<bool> savePromotion({
    String? promotionId,
    required String title,
    required String description,
    required String discountLabel,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isActive,
  }) async {
    if (_currentMallId == null) {
      _error = 'No mall selected. Please login again.';
      notifyListeners();
      return false;
    }

    try {
      final promotions = _firestore
          .collection('malls')
          .doc(_currentMallId)
          .collection('promotions');
      final doc = promotionId == null || promotionId.isEmpty
          ? promotions.doc()
          : promotions.doc(promotionId);
      await doc.set({
        'title': title.trim(),
        'description': description.trim(),
        'discountLabel': discountLabel.trim(),
        'startDate': startDate == null ? null : Timestamp.fromDate(startDate),
        'endDate': endDate == null ? null : Timestamp.fromDate(endDate),
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        if (promotionId == null || promotionId.isEmpty)
          'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _logStaffActivity(
        action: promotionId == null ? 'Promotion created' : 'Promotion updated',
        details: title.trim(),
      );
      return true;
    } catch (e) {
      _error = 'Error saving promotion: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePromotion(String promotionId) async {
    if (_currentMallId == null) return false;
    try {
      await _firestore
          .collection('malls')
          .doc(_currentMallId)
          .collection('promotions')
          .doc(promotionId)
          .delete();
      await _logStaffActivity(
        action: 'Promotion deleted',
        details: promotionId,
      );
      return true;
    } catch (e) {
      _error = 'Error deleting promotion: $e';
      notifyListeners();
      return false;
    }
  }

  DocumentReference<Map<String, dynamic>>? _currentManagerRef() {
    if (_currentMallId == null || _currentManagerId == null) return null;
    return _firestore
        .collection('malls')
        .doc(_currentMallId)
        .collection('managers')
        .doc(_currentManagerId);
  }

  Future<void> loadManagerProfile() async {
    final ref = _currentManagerRef();
    if (ref == null) return;

    try {
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

      _profile = MallManagerProfile.fromManagerDoc(
        mallId: _currentMallId!,
        managerId: _currentManagerId!,
        data: data,
      );
      notifyListeners();
    } catch (_) {
      // Ignore: profile can be loaded later.
    }
  }

  Future<bool> updateManagerProfile({
    required String fullName,
    required String phoneNumber,
    required DateTime? dateOfJoining,
  }) async {
    final ref = _currentManagerRef();
    if (ref == null) {
      _error = 'Not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final current =
          _profile ??
          MallManagerProfile(
            mallId: _currentMallId!,
            managerId: _currentManagerId!,
            email: _currentManagerEmail ?? '',
            fullName: '',
            phoneNumber: '',
            dateOfJoining: null,
          );

      final updated = current.copyWith(
        email: _currentManagerEmail ?? current.email,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        dateOfJoining: dateOfJoining,
      );

      await ref.set(updated.toUpdateMap(), SetOptions(merge: true));
      _profile = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Unable to update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAsMallManager({
    required String managerId,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedManagerId = managerId.trim().toUpperCase();
      final trimmedPassword = password.trim();

      if (normalizedManagerId.isEmpty || trimmedPassword.isEmpty) {
        _error = 'Please enter manager ID and password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final managerIndexSnap = await _firestore
          .collection('manager_index')
          .doc(normalizedManagerId)
          .get();

      if (!managerIndexSnap.exists) {
        _error = 'Manager account not found. Ask admin to reset the password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final indexData = managerIndexSnap.data() ?? <String, dynamic>{};
      final resolvedMallId = (indexData['mallId'] ?? '')
          .toString()
          .trim()
          .toUpperCase();

      if (resolvedMallId.isEmpty) {
        _error = 'Manager is not linked to a valid mall';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final isActive = indexData['isActive'] == null
          ? true
          : indexData['isActive'] == true;
      if (!isActive) {
        _error = 'Manager account is disabled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final passwordHash = (indexData['passwordHash'] ?? '').toString();
      if (passwordHash.isEmpty) {
        _error = 'Manager password is not set. Ask admin to reset it.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (_hashPassword(trimmedPassword) != passwordHash) {
        _error = 'Invalid manager ID or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final mallDoc = await _firestore
          .collection('malls')
          .doc(resolvedMallId)
          .get();
      if (!mallDoc.exists) {
        _error = 'Mall not found for this manager';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final managerDoc = _firestore
          .collection('malls')
          .doc(resolvedMallId)
          .collection('managers')
          .doc(normalizedManagerId);
      final managerSnap = await managerDoc.get();
      if (!managerSnap.exists) {
        _error = 'Manager account not found in mall. Ask admin to recreate it.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final managerData = managerSnap.data() ?? <String, dynamic>{};

      _currentMallId = resolvedMallId;
      _currentManagerId = normalizedManagerId;
      _currentManagerEmail = (managerData['assignedEmail'] ?? '').toString();
      _billingSettings = MallBillingSettings.fromMap(
        mallDoc.data()?['billingSettings'] as Map<String, dynamic>?,
      );

      await managerDoc.set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await managerIndexSnap.reference.set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await loadManagerProfile();
      await _fetchProducts();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      _error = 'Login error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchProducts() async {
    if (_currentMallId == null) {
      print('Current mall ID is null, cannot fetch products');
      return;
    }

    try {
      print('Fetching products for mall: $_currentMallId');
      final snapshot = await _firestore
          .collection('malls')
          .doc(_currentMallId)
          .collection('products')
          .get();

      print('Found ${snapshot.docs.length} products');
      _products = snapshot.docs
          .map((doc) => MallProduct.fromMap(doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching products: $e');
      _error = 'Error fetching products: $e';
      notifyListeners();
    }
  }

  Future<bool> addProduct(MallProduct product) async {
    if (_currentMallId == null) {
      _error = 'No mall selected. Please login again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Ensure we always have a unique Firestore document id.
      // This protects bulk imports from accidental productId collisions.
      final incomingProductId = product.productId.trim();
      final effectiveProductId = incomingProductId.isEmpty
          ? _firestore
              .collection('malls')
              .doc(_currentMallId!)
              .collection('products')
              .doc()
              .id
          : incomingProductId;

      final trimmedBarcode = product.barcode.trim();
      final effectiveBarcode = trimmedBarcode.isEmpty
          ? await _allocateAutoBarcodeEan13()
          : trimmedBarcode;
      final productToSave = MallProduct(
        productId: effectiveProductId,
        name: product.name,
        barcode: effectiveBarcode,
        imageUrl: product.imageUrl,
        imageSourcePage: product.imageSourcePage,
        price: product.price,
        weight: product.weight,
        weightUnit: product.weightUnit,
        unit: product.unit,
        brand: product.brand,
        category: product.category,
        stock: product.stock,
        inStock: product.inStock,
      );

      print('=== ADDING PRODUCT ===');
      print('Mall ID: $_currentMallId');
      print('Product ID: ${productToSave.productId}');
      print('Product Name: ${productToSave.name}');
      print('Product Data: ${productToSave.toMap()}');

      // STEP 1: Validate barcode is unique
      print('Step 1: Checking if barcode already exists...');
      final existingBarcode = await _firestore
          .collection('malls')
          .doc(_currentMallId!)
          .collection('barcodes')
          .doc(productToSave.barcode)
          .get();

      if (existingBarcode.exists) {
        _error =
            'Barcode ${productToSave.barcode} already exists for this mall';
        _isLoading = false;
        notifyListeners();
        print('ERROR: Barcode already exists');
        return false;
      }
      print('✓ Barcode is unique');

      // STEP 2: Save product to Firestore
      print('Step 2: Saving product to Firestore...');
      final productRef = _firestore
          .collection('malls')
          .doc(_currentMallId!)
          .collection('products')
          .doc(productToSave.productId);

      await productRef.set(productToSave.toMap());
      print('✓ Product saved to Firestore');

      // STEP 3: Save barcode mapping
      print('Step 3: Saving barcode mapping...');
      final barcodeRef = _firestore
          .collection('malls')
          .doc(_currentMallId!)
          .collection('barcodes')
          .doc(productToSave.barcode);

      await barcodeRef.set({
        'productId': productToSave.productId,
        'productName': productToSave.name,
        'barcode': productToSave.barcode,
        'imageUrl': productToSave.imageUrl,
        'imageSourcePage': productToSave.imageSourcePage,
        'brand': productToSave.brand,
        'category': productToSave.category,
        'price': productToSave.price,
        'unit': productToSave.unit,
        'inStock': productToSave.inStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✓ Barcode mapping saved');

      // STEP 4: Verify product exists in Firestore
      print('Step 4: Verifying product in Firestore...');
      final savedProduct = await productRef.get();
      if (!savedProduct.exists) {
        _error = 'Product verification failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        print('ERROR: Product not found after save');
        return false;
      }
      print('✓ Product verified in Firestore');
      print('Product data in Firestore: ${savedProduct.data()}');

      // STEP 5: Update local list ONLY after Firestore confirms
      print('Step 5: Updating local product list...');
      _products.add(productToSave);
      await _logStaffActivity(
        action: 'Product added',
        details: '${productToSave.name} (${productToSave.barcode})',
      );
      _isLoading = false;
      notifyListeners();

      print('=== PRODUCT ADDED SUCCESSFULLY ===\n');
      return true;
    } catch (e) {
      print('ERROR during addProduct: $e');
      print('Stack trace: ${StackTrace.current}');
      _error = 'Error adding product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId, String barcode) async {
    if (_currentMallId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Deleting product: $productId from mall: $_currentMallId');

      // Delete product
      await _firestore
          .collection('malls')
          .doc(_currentMallId)
          .collection('products')
          .doc(productId)
          .delete();

      // Delete barcode mapping
      await _firestore
          .collection('malls')
          .doc(_currentMallId)
          .collection('barcodes')
          .doc(barcode)
          .delete();

      print('Product deleted successfully');
      _products.removeWhere((p) => p.productId == productId);
      await _logStaffActivity(
        action: 'Product deleted',
        details: '$productId ($barcode)',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      _error = 'Error deleting product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(MallProduct product) async {
    if (_currentMallId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Updating product: ${product.productId} in mall: $_currentMallId');

      await _firestore
          .collection('malls')
          .doc(_currentMallId)
          .collection('products')
          .doc(product.productId)
          .update(product.toMap());

      // Update barcode mapping if needed
      await _firestore
          .collection('malls')
          .doc(_currentMallId)
          .collection('barcodes')
          .doc(product.barcode)
          .update({
            'productName': product.name,
            'barcode': product.barcode,
            'imageUrl': product.imageUrl,
            'imageSourcePage': product.imageSourcePage,
            'brand': product.brand,
            'category': product.category,
            'price': product.price,
            'unit': product.unit,
            'inStock': product.inStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('Product updated successfully');
      final index = _products.indexWhere(
        (p) => p.productId == product.productId,
      );
      if (index != -1) {
        _products[index] = product;
      }
      await _logStaffActivity(
        action: 'Product updated',
        details: '${product.name} (${product.barcode})',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating product: $e');
      _error = 'Error updating product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBillingSettings(MallBillingSettings settings) async {
    if (_currentMallId == null) {
      _error = 'No mall selected. Please login again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('malls').doc(_currentMallId).set({
        'billingSettings': settings.toMap(),
      }, SetOptions(merge: true));

      _billingSettings = settings;
      await _logStaffActivity(
        action: 'Billing settings updated',
        details:
            'GST ${settings.gstPercent.toStringAsFixed(1)}%, ${settings.extraChargeLabel}',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating billing settings: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentMallId = null;
    _currentManagerId = null;
    _currentManagerEmail = null;
    _profile = null;
    _products = [];
    _billingSettings = const MallBillingSettings();
    _error = null;
    notifyListeners();
  }

  Future<bool> testFirestoreConnection() async {
    try {
      print('=== TESTING FIRESTORE CONNECTION ===');
      if (_currentMallId == null) {
        print('ERROR: No mall ID set');
        return false;
      }

      print('Testing write to: malls/$_currentMallId');

      // Try to write a test document
      final testDoc = _firestore
          .collection('malls')
          .doc(_currentMallId!)
          .collection('_test')
          .doc('test_doc');

      await testDoc.set({'timestamp': DateTime.now().toString()});
      print('✓ Write successful');

      // Try to read it back
      final doc = await testDoc.get();
      if (doc.exists) {
        print('✓ Read successful');
        await testDoc.delete();
        print('✓ Delete successful');
        print('=== FIRESTORE IS WORKING ===\n');
        return true;
      } else {
        print('ERROR: Could not read test document');
        return false;
      }
    } catch (e) {
      print('ERROR: $e');
      print('This likely means Firestore rules are blocking writes');
      print(
        'Check your Firestore security rules at: https://console.firebase.google.com',
      );
      return false;
    }
  }

  Future<void> _logStaffActivity({
    required String action,
    required String details,
  }) async {
    if (_currentMallId == null) {
      return;
    }

    try {
      await _firestore
          .collection('malls')
          .doc(_currentMallId)
          .collection('staff_activity')
          .add({
            'action': action,
            'details': details,
            'managerId': _currentManagerId ?? '',
            'managerEmail': _currentManagerEmail ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      // Non-blocking activity logging.
    }
  }
}
