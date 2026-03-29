import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import '../services/mall_qr_print_service.dart';

class AddMallScreen extends StatefulWidget {
  const AddMallScreen({super.key});

  @override
  State<AddMallScreen> createState() => _AddMallScreenState();
}

class _AddMallScreenState extends State<AddMallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mallNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _areaPincodeCtrl = TextEditingController();
  final _mallNumberCtrl = TextEditingController();
  final _mallCodeCtrl = TextEditingController();
  final _estYearCtrl = TextEditingController();

  String? _generatedMallId;
  String _selectedPlan = 'basic';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;
  bool _isSubmitting = false;

  final planDetails = {
    'basic': {'name': 'Basic', 'products': 1000, 'price': '₹999/month'},
    'pro': {'name': 'Pro', 'products': 5000, 'price': '₹2999/month'},
    'enterprise': {'name': 'Enterprise', 'products': 50000, 'price': 'Custom'},
  };

  @override
  void dispose() {
    _mallNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _areaPincodeCtrl.dispose();
    _mallNumberCtrl.dispose();
    _mallCodeCtrl.dispose();
    _estYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateMallId() async {
    // Validate required fields
    if (_areaPincodeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Area Pincode')),
      );
      return;
    }
    if (_areaPincodeCtrl.text.trim().length != 6 || !RegExp(r'^\d{6}$').hasMatch(_areaPincodeCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area Pincode must be 6 digits')),
      );
      return;
    }
    if (_mallNumberCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Mall Number')),
      );
      return;
    }
    if (_mallNumberCtrl.text.trim().length != 2 || !RegExp(r'^\d{2}$').hasMatch(_mallNumberCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mall Number must be 2 digits')),
      );
      return;
    }
    if (_mallCodeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Mall Code')),
      );
      return;
    }
    if (_mallCodeCtrl.text.trim().length != 2 || !RegExp(r'^[A-Za-z]{2}$').hasMatch(_mallCodeCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mall Code must be 2 letters')),
      );
      return;
    }
    if (_estYearCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Established Year')),
      );
      return;
    }
    if (!RegExp(r'^\d{2,4}$').hasMatch(_estYearCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Year must be 2 or 4 digits')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final adminProvider = context.read<AdminProvider>();
    final mallId = await adminProvider.generateNewMallId(
      areaCode: _areaPincodeCtrl.text.trim(),
      mallNumber: _mallNumberCtrl.text.trim(),
      mallCode: _mallCodeCtrl.text.trim().toUpperCase(),
      estYear: _estYearCtrl.text.trim(),
    );

    if (mallId != null) {
      setState(() => _generatedMallId = mallId);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminProvider.error ?? 'Error generating ID')),
        );
      }
    }

    setState(() => _isGenerating = false);
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_generatedMallId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate a Mall ID')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select subscription dates')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final mall = MallSubscription(
      mallId: _generatedMallId!,
      name: _mallNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      ownerEmail: _ownerEmailCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      subscriptionStartDate: _startDate!,
      subscriptionEndDate: _endDate!,
      planType: _selectedPlan,
      maxProducts: int.parse(planDetails[_selectedPlan]!['products'].toString()),
      isActive: true,
      createdAt: DateTime.now(),
      areaCode: _areaPincodeCtrl.text.trim(),
      mallNumber: int.tryParse(_mallNumberCtrl.text.trim()),
      mallCode: _mallCodeCtrl.text.trim().toUpperCase(),
      estYear: int.tryParse(_estYearCtrl.text.trim()),
    );

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.addNewMall(mall);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mall added successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminProvider.error ?? 'Error adding mall')),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Mall'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mall ID Components Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mall ID Components',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Format: [Area Pincode-6][Mall Number-2][Mall Code-2][Est. Year-2]',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _areaPincodeCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Area Pincode',
                                  hintText: '560001',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _mallNumberCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Mall Number',
                                  hintText: '01',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mallCodeCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Mall Code',
                                  hintText: 'DM',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _estYearCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Est. Year',
                                  hintText: '24 or 2024',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Mall ID Generation Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Generate Unique Mall ID',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_generatedMallId != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Generated',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_generatedMallId != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Mall ID:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _generatedMallId!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_outlined,
                                          size: 18),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: _generatedMallId!),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Mall ID copied to clipboard'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // QR Code
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: QrImageView(
                                    data: _generatedMallId!,
                                    version: QrVersions.auto,
                                    size: 200.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await MallQrPrintService.printSingleLabel(
                                          MallQrLabelData(
                                            mallName: _mallNameCtrl.text.trim().isEmpty
                                                ? 'New Mall'
                                                : _mallNameCtrl.text.trim(),
                                            mallId: _generatedMallId!,
                                            city: _cityCtrl.text.trim().isEmpty
                                                ? 'Unknown City'
                                                : _cityCtrl.text.trim(),
                                            state: _stateCtrl.text.trim().isEmpty
                                                ? 'Unknown State'
                                                : _stateCtrl.text.trim(),
                                          ),
                                        );
                                      } catch (_) {
                                        if (!mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Unable to open the print dialog right now.'),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.print_outlined),
                                    label: const Text('Print QR'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isGenerating ? null : _generateMallId,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Regenerate ID'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isGenerating ? null : _generateMallId,
                              icon: _isGenerating
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_outlined),
                              label: _isGenerating
                                  ? const Text('Generating...')
                                  : const Text('Generate Mall ID'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Mall Information Section
                Text(
                  'Mall Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _mallNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Mall Name',
                    hintText: 'e.g., City Mall, Central Plaza',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Mall name is required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _cityCtrl,
                  decoration: InputDecoration(
                    labelText: 'City',
                    hintText: 'e.g., Delhi, Mumbai',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'City is required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _stateCtrl,
                  decoration: InputDecoration(
                    labelText: 'State',
                    hintText: 'e.g., Delhi, Maharashtra',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'State is required' : null,
                ),
                const SizedBox(height: 24),

                // Owner Information Section
                Text(
                  'Owner Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _ownerNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Owner Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Owner name is required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _ownerEmailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Owner Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Plan Selection Section
                Text(
                  'Select Plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                ...planDetails.entries.map((entry) {
                  final key = entry.key;
                  final details = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: _selectedPlan == key ? 4 : 1,
                      color: _selectedPlan == key
                          ? Colors.blue[50]
                          : Colors.white,
                      child: ListTile(
                        title: Text('${details['name']} Plan'),
                        subtitle: Text(
                          'Max ${details['products']} products • ${details['price']}',
                        ),
                        trailing: Radio<String>(
                          value: key,
                          groupValue: _selectedPlan,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedPlan = value);
                            }
                          },
                        ),
                        onTap: () => setState(() => _selectedPlan = key),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),

                // Subscription Dates Section
                Text(
                  'Subscription Period',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 1,
                        child: InkWell(
                          onTap: _selectStartDate,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : 'Select',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        elevation: 1,
                        child: InkWell(
                          onTap: _selectEndDate,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endDate != null
                                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                      : 'Select',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Add Mall',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
