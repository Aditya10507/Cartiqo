import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';

class ManageSubscriptionScreen extends StatefulWidget {
  final MallSubscription mall;

  const ManageSubscriptionScreen({
    super.key,
    required this.mall,
  });

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  late DateTime _newEndDate;
  late String _selectedPlan;
  late bool _isActive;
  bool _isUpdating = false;

  final planDetails = {
    'basic': {'name': 'Basic', 'products': 1000, 'price': '₹999/month'},
    'pro': {'name': 'Pro', 'products': 5000, 'price': '₹2999/month'},
    'enterprise': {'name': 'Enterprise', 'products': 50000, 'price': 'Custom'},
  };

  @override
  void initState() {
    super.initState();
    _newEndDate = widget.mall.subscriptionEndDate;
    _selectedPlan = widget.mall.planType;
    _isActive = widget.mall.isActive;
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _newEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _newEndDate = picked);
    }
  }

  Future<void> _renew1Year() async {
    setState(() => _newEndDate = _newEndDate.add(const Duration(days: 365)));
  }

  Future<void> _renew3Months() async {
    setState(() => _newEndDate = _newEndDate.add(const Duration(days: 90)));
  }

  Future<void> _saveChanges() async {
    setState(() => _isUpdating = true);

    final updatedMall = MallSubscription(
      mallId: widget.mall.mallId,
      name: widget.mall.name,
      ownerName: widget.mall.ownerName,
      ownerEmail: widget.mall.ownerEmail,
      city: widget.mall.city,
      state: widget.mall.state,
      subscriptionStartDate: widget.mall.subscriptionStartDate,
      subscriptionEndDate: _newEndDate,
      planType: _selectedPlan,
      maxProducts: int.parse(planDetails[_selectedPlan]!['products'].toString()),
      isActive: _isActive,
      createdAt: widget.mall.createdAt,
      areaCode: widget.mall.areaCode,
      estYear: widget.mall.estYear,
      mallCode: widget.mall.mallCode,
      mallNumber: widget.mall.mallNumber,
      active: widget.mall.active,
    );

    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.updateMallSubscription(updatedMall);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription updated successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminProvider.error ?? 'Error updating')),
      );
    }

    setState(() => _isUpdating = false);
  }

  Future<void> _deactivateMall() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Mall'),
        content: const Text(
          'Are you sure you want to deactivate this mall? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() => _isUpdating = true);

              final adminProvider = context.read<AdminProvider>();
              final success =
                  await adminProvider.deactivateMall(widget.mall.mallId);

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mall deactivated successfully!')),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(adminProvider.error ?? 'Error deactivating')),
                );
              }

              setState(() => _isUpdating = false);
            },
            child: const Text(
              'Deactivate',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.mall.isExpired;
    final daysLeft = widget.mall.daysUntilExpiry;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscription'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mall Info Card
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.mall.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${widget.mall.mallId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isActive
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isActive
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.mall.city}, ${widget.mall.state}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Owner',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.mall.ownerName ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current Status
              Text(
                'Current Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.red[50]
                      : daysLeft < 30
                          ? Colors.orange[50]
                          : Colors.green[50],
                  border: Border.all(
                    color: isExpired
                        ? Colors.red[200]!
                        : daysLeft < 30
                            ? Colors.orange[200]!
                            : Colors.green[200]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired
                          ? Icons.error_outline
                          : daysLeft < 30
                              ? Icons.warning_outlined
                              : Icons.check_circle_outline,
                      color: isExpired
                          ? Colors.red[700]
                          : daysLeft < 30
                              ? Colors.orange[700]
                              : Colors.green[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isExpired ? 'Subscription Expired' : 'Active',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isExpired
                                  ? Colors.red[700]
                                  : daysLeft < 30
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isExpired
                                ? 'Expired on ${widget.mall.subscriptionEndDate.day}/${widget.mall.subscriptionEndDate.month}/${widget.mall.subscriptionEndDate.year}'
                                : '$daysLeft days remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired
                                  ? Colors.red[600]
                                  : daysLeft < 30
                                      ? Colors.orange[600]
                                      : Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Renew Options
              if (isExpired)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Renew',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _renew3Months,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Add 3 Months'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _renew1Year,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Add 1 Year'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              // Plan Selection
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
                    color: _selectedPlan == key ? Colors.blue[50] : Colors.white,
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

              // End Date
              Text(
                'Subscription End Date',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 1,
                child: InkWell(
                  onTap: _selectEndDate,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
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
                              '${_newEndDate.day}/${_newEndDate.month}/${_newEndDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_outlined),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              if (_isActive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _deactivateMall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Deactivate Mall',
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
    );
  }
}
