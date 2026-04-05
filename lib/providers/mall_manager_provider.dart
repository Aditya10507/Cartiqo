// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

import '../models/mall_billing_settings.dart';
import '../models/mall_manager_profile.dart';
import '../models/mall_product.dart';
import '../services/mall_manager_api_service.dart';

class MallManagerProvider extends ChangeNotifier {
  final MallManagerApiService _apiService = MallManagerApiService();

  String? _currentMallId;
  String? _currentManagerId;
  String? _currentManagerEmail;
  String? _accessToken;
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

  Stream<List<Map<String, dynamic>>> watchMallPayments() {
    if (_currentMallId == null || _accessToken == null) {
      return Stream.value(const []);
    }

    return _pollingStream(
      () async => (await _apiService.fetchMallPayments(
            token: _requireAccessToken(),
            mallId: _currentMallId!,
          ))
          .take(10)
          .toList(),
    );
  }

  Stream<List<Map<String, dynamic>>> watchMallSalesPayments({int limit = 500}) {
    if (_currentMallId == null || _accessToken == null) {
      return Stream.value(const []);
    }

    return _pollingStream(
      () async => (await _apiService.fetchMallPayments(
            token: _requireAccessToken(),
            mallId: _currentMallId!,
          ))
          .take(limit)
          .toList(),
    );
  }

  Stream<List<Map<String, dynamic>>> watchPromotions() {
    if (_accessToken == null) {
      return Stream.value(const []);
    }

    return _pollingStream(
      () => _apiService.fetchPromotions(_requireAccessToken()),
    );
  }

  Stream<List<Map<String, dynamic>>> watchStaffActivity() {
    if (_accessToken == null) {
      return Stream.value(const []);
    }

    return _pollingStream(
      () => _apiService.fetchStaffActivity(_requireAccessToken()),
    );
  }

  Stream<List<Map<String, dynamic>>> watchAnnouncements() {
    return _pollingStream(_apiService.fetchAnnouncements);
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
      await _apiService.savePromotion(
        token: _requireAccessToken(),
        promotionId: promotionId,
        title: title,
        description: description,
        discountLabel: discountLabel,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
      );
      return true;
    } catch (e) {
      _error = 'Error saving promotion: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePromotion(String promotionId) async {
    if (_accessToken == null) return false;
    try {
      await _apiService.deletePromotion(
        token: _requireAccessToken(),
        promotionId: promotionId,
      );
      return true;
    } catch (e) {
      _error = 'Error deleting promotion: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadManagerProfile() async {
    if (_accessToken == null) return;

    try {
      _profile = await _apiService.fetchProfile(_requireAccessToken());
      notifyListeners();
    } catch (_) {
      // Profile can be refreshed later.
    }
  }

  Future<bool> updateManagerProfile({
    required String fullName,
    required String phoneNumber,
    required DateTime? dateOfJoining,
  }) async {
    if (_accessToken == null) {
      _error = 'Not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _apiService.updateProfile(
        token: _requireAccessToken(),
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfJoining: dateOfJoining,
      );
      _currentManagerEmail = _profile?.email;
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
      final result = await _apiService.login(
        managerId: managerId,
        password: password,
      );

      _accessToken = result.token;
      _currentMallId = result.mallId;
      _currentManagerId = result.managerId;
      _currentManagerEmail = result.email;
      _profile = result.profile;
      _billingSettings = result.billingSettings;

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
    if (_currentMallId == null || _accessToken == null) {
      return;
    }

    try {
      _products = await _apiService.fetchProducts(
        token: _requireAccessToken(),
        mallId: _currentMallId!,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching products: $e';
      notifyListeners();
    }
  }

  Future<bool> addProduct(MallProduct product) async {
    if (_currentMallId == null || _accessToken == null) {
      _error = 'No mall selected. Please login again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _apiService.createProduct(
        token: _requireAccessToken(),
        mallId: _currentMallId!,
        product: product,
      );
      _products.add(created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error adding product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId, String barcode) async {
    if (_currentMallId == null || _accessToken == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteProduct(
        token: _requireAccessToken(),
        mallId: _currentMallId!,
        productId: productId,
      );

      _products.removeWhere((p) => p.productId == productId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error deleting product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(MallProduct product) async {
    if (_currentMallId == null || _accessToken == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateProduct(
        token: _requireAccessToken(),
        mallId: _currentMallId!,
        product: product,
      );

      final index = _products.indexWhere((p) => p.productId == product.productId);
      if (index != -1) {
        _products[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating product: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBillingSettings(MallBillingSettings settings) async {
    if (_currentMallId == null || _accessToken == null) {
      _error = 'No mall selected. Please login again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _billingSettings = await _apiService.updateBillingSettings(
        token: _requireAccessToken(),
        mallId: _currentMallId!,
        settings: settings,
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
    _accessToken = null;
    _profile = null;
    _products = [];
    _billingSettings = const MallBillingSettings();
    _error = null;
    notifyListeners();
  }

  Future<bool> testFirestoreConnection() async {
    return _accessToken != null;
  }

  String _requireAccessToken() {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Mall manager session expired. Please login again.');
    }
    return token;
  }

  Stream<T> _pollingStream<T>(
    Future<T> Function() loader, {
    Duration interval = const Duration(seconds: 15),
  }) async* {
    while (true) {
      yield await loader();
      await Future<void>.delayed(interval);
    }
  }
}
