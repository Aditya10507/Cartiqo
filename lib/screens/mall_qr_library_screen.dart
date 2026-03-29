import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/mall_subscription.dart';
import '../providers/admin_provider.dart';
import '../services/mall_qr_print_service.dart';

class MallQrLibraryScreen extends StatefulWidget {
  const MallQrLibraryScreen({super.key});

  @override
  State<MallQrLibraryScreen> createState() => _MallQrLibraryScreenState();
}

class _MallQrLibraryScreenState extends State<MallQrLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        final malls = provider.malls.where(_matchesSearch).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mall QR Library'),
            actions: [
              IconButton(
                onPressed: malls.isEmpty ? null : () => _printAll(context, malls),
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Print all QR labels',
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                color: Colors.blueGrey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${malls.length} printable mall QR${malls.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Each label includes the mall name, mall ID, and QR code for scanning at the entrance.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value.trim().toLowerCase());
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by mall name, city, state, or mall ID',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: malls.isEmpty ? null : () => _printAll(context, malls),
                        icon: const Icon(Icons.local_printshop_outlined),
                        label: const Text('Print Visible QR Labels'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: malls.isEmpty
                    ? const _EmptyMallQrState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: malls.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final mall = malls[index];
                          return _MallQrCard(
                            mall: mall,
                            onCopy: () => _copyMallId(context, mall.mallId),
                            onPrint: () => _printSingle(context, mall),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _matchesSearch(MallSubscription mall) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final values = [
      mall.name,
      mall.mallId,
      mall.city ?? '',
      mall.state ?? '',
    ];

    return values.any((value) => value.toLowerCase().contains(_searchQuery));
  }

  Future<void> _printAll(BuildContext context, List<MallSubscription> malls) async {
    try {
      await MallQrPrintService.printLabelSheet(
        malls.map(MallQrLabelData.fromMall).toList(),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the print dialog right now.')),
      );
    }
  }

  Future<void> _printSingle(BuildContext context, MallSubscription mall) async {
    try {
      await MallQrPrintService.printSingleLabel(
        MallQrLabelData.fromMall(mall),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to print this mall QR right now.')),
      );
    }
  }

  void _copyMallId(BuildContext context, String mallId) {
    Clipboard.setData(ClipboardData(text: mallId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mall ID copied to clipboard')),
    );
  }
}

class _MallQrCard extends StatelessWidget {
  final MallSubscription mall;
  final VoidCallback onCopy;
  final VoidCallback onPrint;

  const _MallQrCard({
    required this.mall,
    required this.onCopy,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mall.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mall.city ?? 'Unknown City'}, ${mall.state ?? 'Unknown State'}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mall.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: mall.isActive ? Colors.indigo.shade800 : Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: mall.mallId,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mall.mallId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Owner: ${mall.ownerName ?? 'Not set'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copy mall ID',
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPrint,
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print QR Label'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMallQrState extends StatelessWidget {
  const _EmptyMallQrState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_2_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No mall QR labels yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a mall first and its QR label will appear here automatically.',
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
