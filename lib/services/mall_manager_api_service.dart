import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mall_billing_settings.dart';
import '../models/mall_manager_profile.dart';
import '../models/mall_product.dart';
import 'api_config.dart';

class MallManagerLoginResult {
  final String token;
  final String mallId;
  final String managerId;
  final String email;
  final MallManagerProfile profile;
  final MallBillingSettings billingSettings;

  const MallManagerLoginResult({
    required this.token,
    required this.mallId,
    required this.managerId,
    required this.email,
    required this.profile,
    required this.billingSettings,
  });
}

class MallManagerApiService {
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<MallManagerLoginResult> login({
    required String managerId,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/mall-manager/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'managerId': managerId.trim().toUpperCase(),
        'password': password,
      }),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Mall manager login failed.'));
    }

    final manager = Map<String, dynamic>.from(body['manager'] as Map);
    final mall = Map<String, dynamic>.from(body['mall'] as Map);
    final mallId = (manager['mallId'] ?? mall['mallId'] ?? '').toString();
    final normalizedManagerId = (manager['managerId'] ?? '').toString();

    return MallManagerLoginResult(
      token: (body['token'] ?? '').toString(),
      mallId: mallId,
      managerId: normalizedManagerId,
      email: (manager['email'] ?? '').toString(),
      profile: MallManagerProfile.fromMap(
        mallId: mallId,
        managerId: normalizedManagerId,
        data: {
          'assignedEmail': manager['email'],
          'fullName': manager['fullName'],
          'phoneNumber': manager['phoneNumber'],
          'dateOfJoining': manager['dateOfJoining'],
        },
      ),
      billingSettings: MallBillingSettings.fromMap({
        'gstPercent': mall['gstPercent'],
        'taxLabel': mall['taxLabel'],
        'taxPercent': mall['taxPercent'],
        'extraChargeLabel': mall['extraChargeLabel'],
        'extraChargeAmount': mall['extraChargeAmount'],
      }),
    );
  }

  Future<MallManagerProfile> fetchProfile(String token) async {
    final response = await http.get(
      _uri('/api/mall-manager/profile'),
      headers: _authHeaders(token),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to load profile.'));
    }

    final map = Map<String, dynamic>.from(body as Map);
    return MallManagerProfile.fromMap(
      mallId: (map['mallId'] ?? '').toString(),
      managerId: (map['managerId'] ?? '').toString(),
      data: {
        'assignedEmail': map['assignedEmail'],
        'fullName': map['fullName'],
        'phoneNumber': map['phoneNumber'],
        'dateOfJoining': map['dateOfJoining'],
      },
    );
  }

  Future<MallManagerProfile> updateProfile({
    required String token,
    required String fullName,
    required String phoneNumber,
    required DateTime? dateOfJoining,
  }) async {
    final response = await http.put(
      _uri('/api/mall-manager/profile'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'dateOfJoining': dateOfJoining?.toIso8601String(),
      }),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to update profile.'));
    }

    final map = Map<String, dynamic>.from(body as Map);
    return MallManagerProfile.fromMap(
      mallId: (map['mallId'] ?? '').toString(),
      managerId: (map['managerId'] ?? '').toString(),
      data: {
        'assignedEmail': map['assignedEmail'],
        'fullName': map['fullName'],
        'phoneNumber': map['phoneNumber'],
        'dateOfJoining': map['dateOfJoining'],
      },
    );
  }

  Future<List<MallProduct>> fetchProducts({
    required String token,
    required String mallId,
  }) async {
    final response = await http.get(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/products'),
      headers: _authHeaders(token),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to load products.'));
    }

    return (body as List)
        .cast<Map>()
        .map((item) => MallProduct.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<MallProduct> createProduct({
    required String token,
    required String mallId,
    required MallProduct product,
  }) async {
    final response = await http.post(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/products'),
      headers: _authHeaders(token),
      body: jsonEncode(_productToMap(product)),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 201) {
      throw Exception(_extractMessage(body, fallback: 'Failed to create product.'));
    }

    return MallProduct.fromMap(Map<String, dynamic>.from(body as Map));
  }

  Future<MallProduct> updateProduct({
    required String token,
    required String mallId,
    required MallProduct product,
  }) async {
    final response = await http.put(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/products/${product.productId.trim()}'),
      headers: _authHeaders(token),
      body: jsonEncode(_productToMap(product)),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to update product.'));
    }

    return MallProduct.fromMap(Map<String, dynamic>.from(body as Map));
  }

  Future<void> deleteProduct({
    required String token,
    required String mallId,
    required String productId,
  }) async {
    final response = await http.delete(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/products/${productId.trim()}'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 204) {
      final body = _decodeJson(response.body);
      throw Exception(_extractMessage(body, fallback: 'Failed to delete product.'));
    }
  }

  Future<List<Map<String, dynamic>>> fetchMallPayments({
    required String token,
    required String mallId,
  }) async {
    final response = await http.get(
      _uri('/api/payments/malls/${mallId.trim().toUpperCase()}'),
      headers: _authHeaders(token),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to load payments.'));
    }

    return (body as List)
        .cast<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          map['id'] = map['paymentId'] ?? map['id'] ?? '';
          return map;
        })
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final response = await http.get(_uri('/api/announcements'));
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to load announcements.'),
      );
    }

    return (body as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchPromotions(String token) async {
    final response = await http.get(
      _uri('/api/mall-manager/promotions'),
      headers: _authHeaders(token),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to load promotions.'),
      );
    }

    return (body as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> savePromotion({
    required String token,
    String? promotionId,
    required String title,
    required String description,
    required String discountLabel,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isActive,
  }) async {
    final response = await http.post(
      _uri('/api/mall-manager/promotions'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'promotionId': (promotionId ?? '').trim(),
        'title': title.trim(),
        'description': description.trim(),
        'discountLabel': discountLabel.trim(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
      }),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to save promotion.'),
      );
    }
  }

  Future<void> deletePromotion({
    required String token,
    required String promotionId,
  }) async {
    final response = await http.delete(
      _uri('/api/mall-manager/promotions/${promotionId.trim()}'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 204) {
      final body = _decodeJson(response.body);
      throw Exception(
        _extractMessage(body, fallback: 'Failed to delete promotion.'),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchStaffActivity(String token) async {
    final response = await http.get(
      _uri('/api/mall-manager/staff-activity'),
      headers: _authHeaders(token),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to load staff activity.'),
      );
    }

    return (body as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<MallBillingSettings> updateBillingSettings({
    required String token,
    required String mallId,
    required MallBillingSettings settings,
  }) async {
    final response = await http.put(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/billing-settings'),
      headers: _authHeaders(token),
      body: jsonEncode(settings.toMap()),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to update billing settings.'),
      );
    }

    final mall = Map<String, dynamic>.from(body as Map);
    return MallBillingSettings.fromMap({
      'gstPercent': mall['gstPercent'],
      'taxLabel': mall['taxLabel'],
      'taxPercent': mall['taxPercent'],
      'extraChargeLabel': mall['extraChargeLabel'],
      'extraChargeAmount': mall['extraChargeAmount'],
    });
  }

  Map<String, dynamic> _productToMap(MallProduct product) {
    return {
      'productId': product.productId,
      'name': product.name,
      'barcode': product.barcode,
      'imageUrl': product.imageUrl,
      'imageSourcePage': product.imageSourcePage,
      'price': product.price,
      'weight': product.weight,
      'weightUnit': product.weightUnit,
      'unit': product.unit,
      'brand': product.brand,
      'category': product.category,
      'stock': product.stock,
      'inStock': product.inStock,
    };
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(body);
  }

  String _extractMessage(dynamic body, {required String fallback}) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return fallback;
  }
}
