import 'package:flutter/foundation.dart';

import '../models/admin.dart';
import '../models/mall_manager_account.dart';
import '../models/mall_subscription.dart';
import '../services/admin_api_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminApiService _adminApiService = AdminApiService();

  Admin? _currentAdmin;
  List<MallSubscription> _malls = [];
  bool _isLoading = false;
  String? _error;
  String? _accessToken;

  Admin? get currentAdmin => _currentAdmin;
  List<MallSubscription> get malls => _malls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Map<String, dynamic>>> watchAnnouncements() {
    return _pollingStream(_adminApiService.fetchAnnouncements);
  }

  Future<bool> createAnnouncement({
    required String title,
    required String message,
    String audience = 'all',
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _adminApiService.createAnnouncement(
        token: _requireAccessToken(),
        title: title,
        message: message,
        audience: audience,
        createdBy: _currentAdmin?.email ?? _currentAdmin?.name ?? 'admin',
      );
      return true;
    } catch (e) {
      _error = 'Error creating announcement: $e';
      notifyListeners();
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> watchSupportRequests() {
    return _pollingStream(
      () => _adminApiService.fetchSupportRequests(_requireAccessToken()),
    );
  }

  Future<bool> updateSupportRequestStatus({
    required String requestId,
    required String status,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _adminApiService.updateSupportRequestStatus(
        token: _requireAccessToken(),
        requestId: requestId,
        status: status,
      );
      return true;
    } catch (e) {
      _error = 'Error updating support request: $e';
      notifyListeners();
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> watchRecentMallPayments() {
    return _pollingStream(
      () => _adminApiService.fetchRecentPayments(_requireAccessToken()),
    );
  }

  Future<int> getMallManagerCount(String mallId) async {
    try {
      return await _adminApiService.fetchMallManagerCount(
        token: _requireAccessToken(),
        mallId: mallId,
      );
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> getMallManagerCounts(List<String> mallIds) async {
    final results = <String, int>{};
    await Future.wait(
      mallIds.map((mallId) async {
        results[mallId] = await getMallManagerCount(mallId);
      }),
    );
    return results;
  }

  Stream<List<MallManagerAccount>> watchMallManagers(String mallId) {
    return _pollingStream(
      () async => (await _adminApiService.fetchMallManagers(
            token: _requireAccessToken(),
            mallId: mallId,
          ))
          .map((manager) => manager.toMap())
          .toList(),
    ).map(
      (items) => items
          .map((item) => MallManagerAccount.fromMap(mallId, item))
          .toList(),
    );
  }

  Future<bool> createMallManager({
    required String mallId,
    required String managerId,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _adminApiService.createMallManager(
        token: _requireAccessToken(),
        mallId: mallId,
        managerId: managerId,
      );
      return true;
    } catch (e) {
      _error = 'Error creating manager: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlinkMallManager({
    required String mallId,
    required String managerId,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _adminApiService.unlinkMallManager(
        token: _requireAccessToken(),
        mallId: mallId,
        managerId: managerId,
      );
      return true;
    } catch (e) {
      _error = 'Error unlinking manager: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setMallManagerActive({
    required String mallId,
    required String managerId,
    required bool isActive,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _adminApiService.setMallManagerActive(
        token: _requireAccessToken(),
        mallId: mallId,
        managerId: managerId,
        isActive: isActive,
      );
      return true;
    } catch (e) {
      _error = 'Error updating manager: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminLogin(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _adminApiService.login(
        email: email,
        password: password,
      );
      _currentAdmin = result.admin;
      _accessToken = result.token;
      await _fetchMalls();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _generateUniqueMallId({
    required String areaCode,
    required String mallNumber,
    required String mallCode,
    required String estYear,
  }) {
    final yearCode = estYear.length == 4 ? estYear.substring(2) : estYear;
    return '$areaCode$mallNumber${mallCode.toUpperCase()}$yearCode';
  }

  Future<String?> generateNewMallId({
    required String areaCode,
    required String mallNumber,
    required String mallCode,
    required String estYear,
  }) async {
    try {
      if (_malls.isEmpty && _accessToken != null) {
        await _fetchMalls();
      }

      final mallId = _generateUniqueMallId(
        areaCode: areaCode,
        mallNumber: mallNumber,
        mallCode: mallCode,
        estYear: estYear,
      );

      final exists = _malls.any(
        (mall) => mall.mallId.trim().toUpperCase() == mallId,
      );

      if (exists) {
        _error = 'Mall ID already exists. Change the inputs and try again.';
        notifyListeners();
        return null;
      }

      return mallId;
    } catch (e) {
      _error = 'Error generating mall ID: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> addNewMall(MallSubscription mall) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdMall = await _adminApiService.createMall(
        token: _requireAccessToken(),
        mall: mall,
      );
      _malls = [..._malls, createdMall];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error adding mall: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMallSubscription(MallSubscription mall) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedMall = await _adminApiService.updateMall(
        token: _requireAccessToken(),
        mall: mall,
      );

      final index = _malls.indexWhere((m) => m.mallId == mall.mallId);
      if (index != -1) {
        _malls[index] = updatedMall;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating subscription: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateMall(String mallId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminApiService.deactivateMall(
        token: _requireAccessToken(),
        mallId: mallId,
      );

      final index = _malls.indexWhere((m) => m.mallId == mallId);
      if (index != -1) {
        final oldMall = _malls[index];
        _malls[index] = MallSubscription(
          mallId: oldMall.mallId,
          name: oldMall.name,
          ownerName: oldMall.ownerName,
          ownerEmail: oldMall.ownerEmail,
          city: oldMall.city,
          state: oldMall.state,
          subscriptionStartDate: oldMall.subscriptionStartDate,
          subscriptionEndDate: oldMall.subscriptionEndDate,
          planType: oldMall.planType,
          maxProducts: oldMall.maxProducts,
          isActive: false,
          createdAt: oldMall.createdAt,
          areaCode: oldMall.areaCode,
          estYear: oldMall.estYear,
          mallCode: oldMall.mallCode,
          mallNumber: oldMall.mallNumber,
          active: oldMall.active,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error deactivating mall: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchMalls() async {
    try {
      _malls = await _adminApiService.fetchMalls(_requireAccessToken());
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching malls: $e';
      notifyListeners();
    }
  }

  void logout() {
    _currentAdmin = null;
    _malls = [];
    _accessToken = null;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshMalls() async {
    await _fetchMalls();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _requireAccessToken() {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Admin session expired. Please login again.');
    }
    return token;
  }

  Stream<List<Map<String, dynamic>>> _pollingStream(
    Future<List<Map<String, dynamic>>> Function() loader, {
    Duration interval = const Duration(seconds: 15),
  }) async* {
    while (true) {
      yield await loader();
      await Future<void>.delayed(interval);
    }
  }
}
