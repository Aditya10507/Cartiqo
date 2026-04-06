import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin.dart';
import '../models/mall_manager_account.dart';
import '../models/mall_subscription.dart';
import 'api_config.dart';

class AdminApiLoginResult {
  final Admin admin;
  final String token;

  const AdminApiLoginResult({
    required this.admin,
    required this.token,
  });
}

class AdminApiService {
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<List<Map<String, dynamic>>> fetchRecentPayments(String token) async {
    final response = await http.get(
      _uri('/api/payments/recent'),
      headers: _authHeaders(token),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to load recent payments.'),
      );
    }

    return (body as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
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

  Future<void> createAnnouncement({
    required String token,
    required String title,
    required String message,
    required String audience,
    required String createdBy,
  }) async {
    final response = await http.post(
      _uri('/api/announcements'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'title': title.trim(),
        'message': message.trim(),
        'audience': audience,
        'createdBy': createdBy.trim(),
      }),
    );

    if (response.statusCode != 201) {
      final body = _decodeJson(response.body);
      throw Exception(
        _extractMessage(body, fallback: 'Failed to create announcement.'),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchSupportRequests(String token) async {
    final response = await http.get(
      _uri('/api/supportrequests'),
      headers: _authHeaders(token),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to load support requests.'),
      );
    }

    return (body as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> updateSupportRequestStatus({
    required String token,
    required String requestId,
    required String status,
  }) async {
    final response = await http.post(
      _uri('/api/supportrequests/${requestId.trim()}/status'),
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 204) {
      final body = _decodeJson(response.body);
      throw Exception(
        _extractMessage(
          body,
          fallback: 'Failed to update support request status.',
        ),
      );
    }
  }

  Future<void> createSupportRequest({
    required String type,
    required String name,
    required String email,
    required String message,
  }) async {
    final response = await http.post(
      _uri('/api/supportrequests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type.trim(),
        'name': name.trim(),
        'email': email.trim(),
        'message': message.trim(),
      }),
    );

    if (response.statusCode != 201) {
      final body = _decodeJson(response.body);
      throw Exception(
        _extractMessage(body, fallback: 'Failed to submit support request.'),
      );
    }
  }

  Future<AdminApiLoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Admin login failed.'));
    }

    final user = Map<String, dynamic>.from(body['user'] as Map);
    return AdminApiLoginResult(
      admin: Admin.fromMap(user),
      token: (body['token'] ?? '').toString(),
    );
  }

  Future<List<MallSubscription>> fetchMalls(String token) async {
    final response = await http.get(
      _uri('/api/malls'),
      headers: _authHeaders(token),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to load malls.'));
    }

    return (body as List)
        .cast<Map>()
        .map((item) => MallSubscription.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<MallSubscription> createMall({
    required String token,
    required MallSubscription mall,
  }) async {
    final response = await http.post(
      _uri('/api/malls'),
      headers: _authHeaders(token),
      body: jsonEncode(_mallToApiMap(mall)),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 201) {
      throw Exception(_extractMessage(body, fallback: 'Failed to create mall.'));
    }

    return MallSubscription.fromMap(Map<String, dynamic>.from(body as Map));
  }

  Future<MallSubscription> updateMall({
    required String token,
    required MallSubscription mall,
  }) async {
    final response = await http.put(
      _uri('/api/malls/${mall.mallId}'),
      headers: _authHeaders(token),
      body: jsonEncode(_mallToApiMap(mall)),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to update mall.'));
    }

    return MallSubscription.fromMap(Map<String, dynamic>.from(body as Map));
  }

  Future<void> deactivateMall({
    required String token,
    required String mallId,
  }) async {
    final response = await http.post(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/deactivate'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 204) {
      final body = _decodeJson(response.body);
      throw Exception(
        _extractMessage(body, fallback: 'Failed to deactivate mall.'),
      );
    }
  }

  Future<int> fetchMallManagerCount({
    required String token,
    required String mallId,
  }) async {
    final response = await http.get(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/managers/count'),
      headers: _authHeaders(token),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to load manager count.'),
      );
    }

    return int.tryParse((body['count'] ?? 0).toString()) ?? 0;
  }

  Future<List<MallManagerAccount>> fetchMallManagers({
    required String token,
    required String mallId,
  }) async {
    final normalizedMallId = mallId.trim().toUpperCase();
    final response = await http.get(
      _uri('/api/malls/$normalizedMallId/managers'),
      headers: _authHeaders(token),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to load managers.'),
      );
    }

    return (body as List)
        .cast<Map>()
        .map(
          (item) => MallManagerAccount.fromMap(
            normalizedMallId,
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> createMallManager({
    required String token,
    required String mallId,
    required String managerId,
  }) async {
    final normalizedMallId = mallId.trim().toUpperCase();
    final response = await http.post(
      _uri('/api/malls/$normalizedMallId/managers'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'mallId': normalizedMallId,
        'managerId': managerId.trim().toUpperCase(),
      }),
    );

    if (response.statusCode != 201) {
      final body = _decodeJson(response.body);
      throw Exception(
        _extractMessage(body, fallback: 'Failed to create manager.'),
      );
    }
  }

  Future<void> unlinkMallManager({
    required String token,
    required String mallId,
    required String managerId,
  }) async {
    final response = await http.post(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/managers/${managerId.trim().toUpperCase()}/unlink'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 204) {
      final body = _decodeJson(response.body);
      throw Exception(
        _extractMessage(body, fallback: 'Failed to unlink manager.'),
      );
    }
  }

  Future<void> setMallManagerActive({
    required String token,
    required String mallId,
    required String managerId,
    required bool isActive,
  }) async {
    final response = await http.post(
      _uri('/api/malls/${mallId.trim().toUpperCase()}/managers/${managerId.trim().toUpperCase()}/active'),
      headers: _authHeaders(token),
      body: jsonEncode({'isActive': isActive}),
    );

    if (response.statusCode != 204) {
      final body = _decodeJson(response.body);
      throw Exception(
        _extractMessage(body, fallback: 'Failed to update manager.'),
      );
    }
  }

  Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _mallToApiMap(MallSubscription mall) {
    return {
      'mallId': mall.mallId,
      'name': mall.name,
      'ownerName': mall.ownerName,
      'ownerEmail': mall.ownerEmail,
      'city': mall.city,
      'state': mall.state,
      'subscriptionStartDate': mall.subscriptionStartDate.toIso8601String(),
      'subscriptionEndDate': mall.subscriptionEndDate.toIso8601String(),
      'planType': mall.planType,
      'maxProducts': mall.maxProducts,
      'isActive': mall.isActive,
      'createdAt': mall.createdAt.toIso8601String(),
      'areaCode': mall.areaCode,
      'estYear': mall.estYear,
      'mallCode': mall.mallCode,
      'mallNumber': mall.mallNumber,
      'active': mall.active,
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
