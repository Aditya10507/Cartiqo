import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mall_billing_settings.dart';
import '../models/mall_product.dart';
import 'api_config.dart';

class StorefrontCheckoutRequest {
  final String mallId;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final int total;
  final int subtotal;
  final int extraCharge;
  final String extraChargeLabel;
  final int gst;
  final double gstPercent;
  final int otherTax;
  final String otherTaxLabel;
  final double otherTaxPercent;
  final String paymentMethod;
  final String paymentReference;
  final List<Map<String, dynamic>> items;

  const StorefrontCheckoutRequest({
    required this.mallId,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.total,
    required this.subtotal,
    required this.extraCharge,
    required this.extraChargeLabel,
    required this.gst,
    required this.gstPercent,
    required this.otherTax,
    required this.otherTaxLabel,
    required this.otherTaxPercent,
    required this.paymentMethod,
    required this.paymentReference,
    required this.items,
  });
}

class StorefrontApiService {
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<List<MallProduct>> fetchProducts(String mallId) async {
    final response = await http.get(
      _uri('/api/public/malls/${mallId.trim().toUpperCase()}/products'),
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

  Future<MallProduct> fetchProductByBarcode({
    required String mallId,
    required String barcode,
  }) async {
    final response = await http.get(
      _uri('/api/public/malls/${mallId.trim().toUpperCase()}/products/barcode/${Uri.encodeComponent(barcode.trim())}'),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Barcode not found in this mall.'),
      );
    }

    return MallProduct.fromMap(Map<String, dynamic>.from(body as Map));
  }

  Future<MallBillingSettings> fetchBillingSettings(String mallId) async {
    final response = await http.get(
      _uri('/api/public/malls/${mallId.trim().toUpperCase()}/billing-settings'),
    );
    final body = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Failed to load billing settings.'),
      );
    }

    return MallBillingSettings.fromMap(Map<String, dynamic>.from(body as Map));
  }

  Future<void> completeCheckout(StorefrontCheckoutRequest request) async {
    final response = await http.post(
      _uri('/api/public/malls/${request.mallId.trim().toUpperCase()}/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mallId': request.mallId.trim().toUpperCase(),
        'userId': request.userId,
        'customerName': request.customerName,
        'customerEmail': request.customerEmail,
        'customerPhone': request.customerPhone,
        'total': request.total,
        'subtotal': request.subtotal,
        'extraCharge': request.extraCharge,
        'extraChargeLabel': request.extraChargeLabel,
        'gst': request.gst,
        'gstPercent': request.gstPercent,
        'otherTax': request.otherTax,
        'otherTaxLabel': request.otherTaxLabel,
        'otherTaxPercent': request.otherTaxPercent,
        'paymentMethod': request.paymentMethod,
        'paymentReference': request.paymentReference,
        'items': request.items,
      }),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(body, fallback: 'Unable to save checkout history.'),
      );
    }
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
