import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mall_manager_provider.dart';

class MallManagerProfileScreen extends StatefulWidget {
  const MallManagerProfileScreen({super.key});

  @override
  State<MallManagerProfileScreen> createState() =>
      _MallManagerProfileScreenState();
}

class _MallManagerProfileScreenState extends State<MallManagerProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  DateTime? _joiningDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MallManagerProvider>();
    final profile = provider.profile;

    _nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phoneNumber ?? '');
    _joiningDate = profile?.dateOfJoining;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MallManagerProvider>().loadManagerProfile();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MallManagerProvider>();
    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Profile'),
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
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mall ID: ${provider.currentMallId ?? ''}  |  Manager ID: ${provider.currentManagerId ?? ''}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Email: ${provider.currentManagerEmail ?? profile?.email ?? ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickJoiningDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Joining',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      child: Text(
                        _joiningDate == null
                            ? 'Select date'
                            : _formatDate(_joiningDate!),
                      ),
                    ),
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
              label: Text(_saving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  Future<void> _pickJoiningDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => _joiningDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final ok = await context.read<MallManagerProvider>().updateManagerProfile(
          fullName: _nameCtrl.text,
          phoneNumber: _phoneCtrl.text,
          dateOfJoining: _joiningDate,
        );

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile saved' : context.read<MallManagerProvider>().error ?? '',
        ),
      ),
    );
  }
}

