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
                      otherTaxPercent: billingSettings.taxPercent,
                      otherTax: otherTax,
                      grandTotal: grandTotal,
                    ),
                  ],
                ),
          bottomNavigationBar: items.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentMethodScreen(
                              mallId: mallId,
                              subtotal: subtotal,
                              extraCharge: extraCharge,
                              extraChargeLabel: billingSettings.extraChargeLabel,
                              gstPercent: billingSettings.gstPercent,
                              gst: gst,
                              otherTaxLabel: billingSettings.taxLabel,
                              otherTaxPercent: billingSettings.taxPercent,
                              otherTax: otherTax,
                              grandTotal: grandTotal,
                              items: List<CartItem>.from(items),
                            ),
                          ),
                        );
                      },
                      child: Text('Proceed to Payment - Rs $grandTotal'),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class PaymentMethodScreen extends StatefulWidget {
  final String mallId;
  final List<CartItem> items;
  final int subtotal;
  final int extraCharge;
  final String extraChargeLabel;
  final double gstPercent;
  final int gst;
  final String otherTaxLabel;
  final double otherTaxPercent;
  final int otherTax;
  final int grandTotal;

  const PaymentMethodScreen({
    super.key,
    required this.mallId,
    required this.items,
    required this.subtotal,
    required this.extraCharge,
    required this.extraChargeLabel,
    required this.gstPercent,
    required this.gst,
    required this.otherTaxLabel,
    required this.otherTaxPercent,
    required this.otherTax,
    required this.grandTotal,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedMethod = 'UPI';

  static const List<_PaymentMethodOption> _options = [
    _PaymentMethodOption(
      title: 'UPI',
      subtitle: 'Pay instantly with UPI apps',
      icon: Icons.qr_code_2_outlined,
    ),
    _PaymentMethodOption(
      title: 'Card',
      subtitle: 'Credit card or debit card',
      icon: Icons.credit_card_outlined,
    ),
    _PaymentMethodOption(
      title: 'Wallet',
      subtitle: 'SwiftPay, Paytm, PhonePe wallet',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _PaymentMethodOption(
      title: 'Cash on Pickup',
      subtitle: 'Pay at the mall billing counter',
      icon: Icons.payments_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Method')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _CheckoutHeader(
            title: 'Choose how you want to pay',
            subtitle: 'Like checkout flows in delivery apps, pick one option below.',
          ),
          const SizedBox(height: 16),
          ..._options.map(
            (option) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: _selectedMethod == option.title,
                onChanged: (_) {
                  setState(() => _selectedMethod = option.title);
                },
                secondary: Icon(option.icon),
                title: Text(option.title),
                subtitle: Text(option.subtitle),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Bill Total'),
              trailing: Text(
                'Rs ${widget.grandTotal}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentGatewayScreen(
                    mallId: widget.mallId,
                    items: widget.items,
                    paymentMethod: _selectedMethod,
                    subtotal: widget.subtotal,
                    extraCharge: widget.extraCharge,
                    extraChargeLabel: widget.extraChargeLabel,
                    gstPercent: widget.gstPercent,
                    gst: widget.gst,
                    otherTaxLabel: widget.otherTaxLabel,
                    otherTaxPercent: widget.otherTaxPercent,
                    otherTax: widget.otherTax,
                    grandTotal: widget.grandTotal,
                  ),
                ),
              );
            },
            child: const Text('Proceed to Payment'),
          ),
        ),
      ),
    );
  }
}

class PaymentGatewayScreen extends StatefulWidget {
  final String mallId;
  final List<CartItem> items;
  final String paymentMethod;
  final int subtotal;
  final int extraCharge;
  final String extraChargeLabel;
  final double gstPercent;
  final int gst;
  final String otherTaxLabel;
  final double otherTaxPercent;
  final int otherTax;
  final int grandTotal;

  const PaymentGatewayScreen({
    super.key,
    required this.mallId,
    required this.items,
    required this.paymentMethod,
    required this.subtotal,
    required this.extraCharge,
    required this.extraChargeLabel,
    required this.gstPercent,
    required this.gst,
    required this.otherTaxLabel,
    required this.otherTaxPercent,
    required this.otherTax,
    required this.grandTotal,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final _upiController = TextEditingController(text: 'aditya@upi');
  final _cardNumberController = TextEditingController(text: '4242 4242 4242 4242');
  final _cardNameController = TextEditingController(text: 'Cartiqo User');
  final _expiryController = TextEditingController(text: '12/28');
  final _cvvController = TextEditingController(text: '123');

  bool _processing = false;

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Gateway')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CheckoutHeader(
            title: '${widget.paymentMethod} Payment',
            subtitle: 'Review the gateway details and complete your payment securely.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payable Amount: Rs ${widget.grandTotal}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mall ID: ${widget.mallId}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildGatewayFields(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _processing ? null : _completePayment,
            child: _processing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Pay Rs ${widget.grandTotal}'),
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayFields() {
    switch (widget.paymentMethod) {
      case 'UPI':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter your UPI ID',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'Card':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cardNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name on Card',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryController,
                        decoration: const InputDecoration(
                          labelText: 'Expiry',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case 'Wallet':
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Payment',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.account_balance_wallet_outlined),
                  title: Text('SwiftPay Wallet'),
                  subtitle: Text('Available balance will be used automatically'),
                ),
              ],
            ),
          ),
        );
      default:
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.storefront_outlined),
              title: Text('Cash on Pickup'),
              subtitle: Text('Show this bill at the mall counter and pay there.'),
            ),
          ),
        );
    }
  }

  Future<void> _completePayment() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(seconds: 2));

    final reference = _buildReference();
    final success = await context.read<UserAuthProvider>().saveCheckoutHistory(
          mallId: widget.mallId,
          total: widget.grandTotal,
          subtotal: widget.subtotal,
          extraCharge: widget.extraCharge,
          extraChargeLabel: widget.extraChargeLabel,
          gst: widget.gst,
          gstPercent: widget.gstPercent,
          otherTax: widget.otherTax,
          otherTaxLabel: widget.otherTaxLabel,
          otherTaxPercent: widget.otherTaxPercent,
          paymentMethod: widget.paymentMethod,
          paymentReference: reference,
          items: widget.items
              .map(
                (item) => {
                  'productId': item.productId,
                  'name': item.name,
                  'barcode': item.barcode,
                  'price': item.price,
                  'qty': item.qty,
                  'unit': item.unit,
                  'lineTotal': item.lineTotal,
                },
              )
              .toList(),
        );

    if (!mounted) {
      return;
    }

    setState(() => _processing = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<UserAuthProvider>().error ??
                'Unable to complete payment',
          ),
        ),
      );
      return;
    }

    context.read<CartProvider>().clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          amount: widget.grandTotal,
          paymentMethod: widget.paymentMethod,
          paymentReference: reference,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  String _buildReference() {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = Random().nextInt(9000) + 1000;
    return '${widget.paymentMethod.toUpperCase().replaceAll(' ', '')}-$stamp-$suffix';
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final int amount;
  final String paymentMethod;
  final String paymentReference;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.paymentMethod,
    required this.paymentReference,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payment Successful'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.green[100],
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green[700],
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Completed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Rs $amount paid via $paymentMethod',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Reference: $paymentReference',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CheckoutHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _BillItemCard extends StatelessWidget {
  final CartItem item;

  const _BillItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('Barcode: ${item.barcode}\n${item.qty} x Rs ${item.price}'),
        trailing: Text(
          'Rs ${item.lineTotal}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String mallId;
  final int itemCount;
  final int subtotal;
  final String extraChargeLabel;
  final int extraCharge;
  final double gstPercent;
  final int gst;
  final String otherTaxLabel;
  final double otherTaxPercent;
  final int otherTax;
  final int grandTotal;

  const _SummaryCard({
    required this.mallId,
    required this.itemCount,
    required this.subtotal,
    required this.extraChargeLabel,
    required this.extraCharge,
    required this.gstPercent,
    required this.gst,
    required this.otherTaxLabel,
    required this.otherTaxPercent,
    required this.otherTax,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(label: 'Mall ID', value: mallId),
            _SummaryRow(label: 'Items', value: '$itemCount'),
            _SummaryRow(label: 'Subtotal', value: 'Rs $subtotal'),
            if (extraCharge > 0)
              _SummaryRow(label: extraChargeLabel, value: 'Rs $extraCharge'),
            if (gst > 0)
              _SummaryRow(
                label: 'GST (${gstPercent.toStringAsFixed(1)}%)',
                value: 'Rs $gst',
              ),
            if (otherTax > 0)
              _SummaryRow(
                label: '$otherTaxLabel (${otherTaxPercent.toStringAsFixed(1)}%)',
                value: 'Rs $otherTax',
              ),
            const Divider(),
            _SummaryRow(
              label: 'Grand Total',
              value: 'Rs $grandTotal',
              isEmphasis: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isEmphasis ? FontWeight.w800 : FontWeight.w500,
      fontSize: isEmphasis ? 17 : 14,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PaymentMethodOption {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PaymentMethodOption({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
