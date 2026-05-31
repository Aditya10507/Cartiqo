import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mall_billing_settings.dart';
import '../models/mall_product.dart';

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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<MallProduct>> fetchProducts(String mallId) async {
    final snapshot = await _db
        .collection('malls')
        .doc(mallId.trim().toUpperCase())
        .collection('products')
        .get();

    return snapshot.docs
        .map((doc) => MallProduct.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<MallProduct> fetchProductByBarcode({
    required String mallId,
    required String barcode,
  }) async {
    final snapshot = await _db
        .collection('malls')
        .doc(mallId.trim().toUpperCase())
        .collection('products')
        .where('barcode', isEqualTo: barcode.trim())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Barcode not found in this mall.');
    }

    return MallProduct.fromMap(
      {...snapshot.docs.first.data(), 'id': snapshot.docs.first.id},
    );
  }

  Future<MallBillingSettings> fetchBillingSettings(String mallId) async {
    final doc = await _db
        .collection('malls')
        .doc(mallId.trim().toUpperCase())
        .collection('settings')
        .doc('billing')
        .get();

    if (!doc.exists) {
      throw Exception('Failed to load billing settings.');
    }

    return MallBillingSettings.fromMap(doc.data()!);
  }
}
