import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class UserProfileApiService {
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    final response = await http.get(_uri('/api/public/users/${userId.trim()}'));
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to load profile.'));
    }

    return Map<String, dynamic>.from(body as Map);
  }

  Future<Map<String, dynamic>> upsertProfile({
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.put(
      _uri('/api/public/users/${userId.trim()}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to update profile.'));
    }

    return Map<String, dynamic>.from(body as Map);
  }

  Future<List<Map<String, dynamic>>> fetchBills(String userId) async {
    final response = await http.get(
      _uri('/api/public/users/${userId.trim()}/bills'),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to load bills.'));
    }

    return (body as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchPayments(String userId) async {
    final response = await http.get(
      _uri('/api/public/users/${userId.trim()}/payments'),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(body, fallback: 'Failed to load payments.'));
    }

    return (body as List)
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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
