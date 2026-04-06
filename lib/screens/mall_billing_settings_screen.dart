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
                children: [
                  const Text(
                    'Billing Rules',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set GST, tax, and extra charges manually for this mall. Checkout will use only these values.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _gstCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'GST %',
                      hintText: 'e.g. 18',
                      prefixIcon: Icon(Icons.percent_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taxLabelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Additional Tax Label',
                      hintText: 'e.g. Service Tax',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Additional Tax %',
                      hintText: 'e.g. 2.5',
                      prefixIcon: Icon(Icons.percent_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _extraChargeLabelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Extra Charge Label',
                      hintText: 'e.g. Packing Charges',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _extraChargeCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Extra Charge Amount',
                      hintText: 'e.g. 12',
                      prefixIcon: Icon(Icons.currency_rupee_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.blueGrey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Summary',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('GST: ${settings.gstPercent.toStringAsFixed(1)}%'),
                  Text(
                    '${settings.taxLabel}: ${settings.taxPercent.toStringAsFixed(1)}%',
                  ),
                  Text(
                    '${settings.extraChargeLabel}: Rs ${settings.extraChargeAmount.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final validationMessage = _validateInputs();
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    setState(() => _saving = true);

    final settings = MallBillingSettings(
      gstPercent: double.tryParse(_gstCtrl.text.trim()) ?? 0,
      taxLabel: _taxLabelCtrl.text.trim().isEmpty
          ? 'Tax'
          : _taxLabelCtrl.text.trim(),
      taxPercent: double.tryParse(_taxCtrl.text.trim()) ?? 0,
      extraChargeLabel: _extraChargeLabelCtrl.text.trim().isEmpty
          ? 'Extra Charges'
          : _extraChargeLabelCtrl.text.trim(),
      extraChargeAmount: double.tryParse(_extraChargeCtrl.text.trim()) ?? 0,
    );

    final provider = context.read<MallManagerProvider>();
    final success = await provider.updateBillingSettings(settings);

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Billing settings updated'
              : provider.error ?? 'Unable to update billing settings',
        ),
      ),
    );

    if (success) {
      Navigator.pop(context);
    }
  }

  String? _validateInputs() {
    final gst = double.tryParse(_gstCtrl.text.trim());
    final tax = double.tryParse(_taxCtrl.text.trim());
    final extraCharge = double.tryParse(_extraChargeCtrl.text.trim());

    if (_gstCtrl.text.trim().isNotEmpty && gst == null) {
      return 'GST must be a valid number.';
    }
    if (_taxCtrl.text.trim().isNotEmpty && tax == null) {
      return 'Additional tax must be a valid number.';
    }
    if (_extraChargeCtrl.text.trim().isNotEmpty && extraCharge == null) {
      return 'Extra charge amount must be a valid number.';
    }
    if ((gst ?? 0) < 0 || (tax ?? 0) < 0 || (extraCharge ?? 0) < 0) {
      return 'Billing values cannot be negative.';
    }

    final taxLabel = _taxLabelCtrl.text.trim();
    if (taxLabel.isNotEmpty && _looksNumeric(taxLabel)) {
      return 'Additional tax label should be text, not just a number.';
    }

    final extraChargeLabel = _extraChargeLabelCtrl.text.trim();
    if (extraChargeLabel.isNotEmpty && _looksNumeric(extraChargeLabel)) {
      return 'Extra charge label should be text, not just a number.';
    }

    return null;
  }

  bool _looksNumeric(String value) {
    return RegExp(r'^\d+(\.\d+)?$').hasMatch(value);
  }
}
