import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mall_manager_provider.dart';
import '../services/file_download_service.dart';
import '../widgets/sales_pivot_charts.dart';

enum _SalesPreset { today, last7, last30, thisMonth, thisYear, custom, all }

enum _GroupBy { day, week, month, year }

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  static const _monthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _searchCtrl = TextEditingController();
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  _SalesPreset _preset = _SalesPreset.last7;
  _GroupBy _groupBy = _GroupBy.day;
  DateTimeRange? _customRange;
  String _method = 'All';
  String _status = 'All';
  int _limit = 500;
  int _refreshNonce = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MallManagerProvider>();
    final mallId = provider.currentMallId ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: Text(
          mallId.isEmpty ? 'Sales Dashboard' : 'Sales Dashboard - $mallId',
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(_refreshNonce),
        stream: provider.watchMallSalesPayments(limit: _limit),
        builder: (context, snapshot) {
          final payments = snapshot.data ?? const <Map<String, dynamic>>[];
          final filtered = payments.where(_matchesFilters).toList()
            ..sort(
              (a, b) => (_createdAt(b) ?? DateTime(2000)).compareTo(
                _createdAt(a) ?? DateTime(2000),
              ),
            );

          final methodOptions =
              <String>{
                  'All',
                  ...payments
                      .map((p) => (p['method'] ?? '').toString().trim())
                      .where((s) => s.isNotEmpty),
                }.toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          final statusOptions =
              <String>{
                  'All',
                  ...payments
                      .map((p) => (p['status'] ?? '').toString().trim())
                      .where((s) => s.isNotEmpty),
                }.toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          final totalSales = filtered.fold<double>(
            0,
            (total, p) => total + ((p['amount'] as num?)?.toDouble() ?? 0),
          );
          final avgOrder = filtered.isEmpty
              ? 0.0
              : totalSales / filtered.length;
          final buckets = _buildBuckets(filtered);
          final chartPoints = [...buckets]
            ..sort((a, b) => a.key.compareTo(b.key));
          final methodTotals = <String, double>{};
          for (final p in filtered) {
            final method = (p['method'] ?? 'Other').toString().trim();
            if (method.isEmpty) continue;
            methodTotals[method] =
                (methodTotals[method] ?? 0) +
                ((p['amount'] as num?)?.toDouble() ?? 0);
          }
          final topBucket = buckets.isEmpty
              ? null
              : buckets.reduce((a, b) => a.sales >= b.sales ? a : b);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _HeroHeader(
                onRefresh: () {
                  setState(() => _refreshNonce++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshing sales data...')),
                  );
                },
                onExport: filtered.isEmpty ? null : () => _exportCsv(filtered),
              ),
              const SizedBox(height: 14),
              _Card(
                child: _FilterBar(
                  searchCtrl: _searchCtrl,
                  method: _method,
                  status: _status,
                  limit: _limit,
                  groupBy: _groupBy,
                  preset: _preset,
                  customRange: _customRange,
                  methodOptions: methodOptions,
                  statusOptions: statusOptions,
                  onSearchChanged: () => setState(() {}),
                  onPresetChanged: (preset) async {
                    if (preset == _SalesPreset.custom) {
                      final picked = await _pickCustomRange();
                      if (picked == null) return;
                      setState(() {
                        _preset = preset;
                        _customRange = picked;
                      });
                      return;
                    }
                    setState(() => _preset = preset);
                  },
                  onGroupByChanged: (value) => setState(() => _groupBy = value),
                  onMethodChanged: (value) => setState(() => _method = value),
                  onStatusChanged: (value) => setState(() => _status = value),
                  onLimitChanged: (value) => setState(() => _limit = value),
                  onClearAll: () => setState(() {
                    _searchCtrl.text = '';
                    _method = 'All';
                    _status = 'All';
                    _preset = _SalesPreset.last7;
                    _groupBy = _GroupBy.day;
                    _customRange = null;
                  }),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 900;
                  return GridView.count(
                    crossAxisCount: compact ? 2 : 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: compact ? 1.55 : 1.85,
                    children: [
                      _Metric(
                        label: 'Orders',
                        value: '${filtered.length}',
                        icon: Icons.receipt_long_outlined,
                        accent: const Color(0xFF0B5ED7),
                      ),
                      _Metric(
                        label: 'Sales',
                        value: _currency(totalSales),
                        icon: Icons.currency_rupee_outlined,
                        accent: const Color(0xFF12B886),
                      ),
                      _Metric(
                        label: 'Avg order',
                        value: _currency(avgOrder),
                        icon: Icons.analytics_outlined,
                        accent: const Color(0xFFFF9F1C),
                      ),
                      _Metric(
                        label: 'Loaded',
                        value: '${payments.length}',
                        icon: Icons.cloud_download_outlined,
                        accent: const Color(0xFF7C3AED),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1100;
                  final summary = _ConsolidatedSummaryCard(
                    groupBy: _groupBy,
                    topBucket: topBucket,
                    totalBuckets: buckets.length,
                    currency: _currency,
                  );
                  final pivot = SalesPivotCharts(
                    title: 'Pivot charts (${_ConsolidatedSummaryCard._groupLabel(_groupBy)})',
                    points: chartPoints
                        .map(
                          (b) => SalesBucketPoint(
                            label: b.label,
                            orders: b.orders,
                            sales: b.sales,
                          ),
                        )
                        .toList(),
                    methodTotals: methodTotals,
                    currency: _currency,
                  );

                  if (compact) {
                    return Column(
                      children: [pivot, const SizedBox(height: 12), summary],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: pivot),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: summary),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _Card(
                child: _PaymentsTable(
                  rows: filtered,
                  vertical: _verticalController,
                  horizontal: _horizontalController,
                  currency: _currency,
                  fmt: _fmt,
                  createdAt: _createdAt,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_Bucket> _buildBuckets(List<Map<String, dynamic>> rows) {
    final grouped = <String, _BucketAccumulator>{};
    for (final p in rows) {
      final dt = _createdAt(p);
      if (dt == null) continue;
      final key = _bucketKey(dt);
      final label = _bucketLabel(dt);
      final amount = ((p['amount'] as num?)?.toDouble() ?? 0);
      final acc = grouped.putIfAbsent(key, () => _BucketAccumulator(label));
      acc.orders++;
      acc.sales += amount;
    }
    final list =
        grouped.entries
            .map(
              (e) => _Bucket(
                key: e.key,
                label: e.value.label,
                orders: e.value.orders,
                sales: e.value.sales,
              ),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    // Keep the trend readable when a lot of rows are loaded.
    if (list.length > 18) {
      return list.sublist(list.length - 18);
    }
    return list;
  }

  String _bucketKey(DateTime dt) {
    switch (_groupBy) {
      case _GroupBy.day:
        return _fmt(dt);
      case _GroupBy.week:
        final start = DateTime(
          dt.year,
          dt.month,
          dt.day,
        ).subtract(Duration(days: dt.weekday - 1));
        return _fmt(start);
      case _GroupBy.month:
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      case _GroupBy.year:
        return '${dt.year}';
    }
  }

  String _bucketLabel(DateTime dt) {
    switch (_groupBy) {
      case _GroupBy.day:
        return _fmt(dt);
      case _GroupBy.week:
        final start = DateTime(
          dt.year,
          dt.month,
          dt.day,
        ).subtract(Duration(days: dt.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${_fmt(start)} to ${_fmt(end)}';
      case _GroupBy.month:
        return '${_monthLabel(dt.month)} ${dt.year}';
      case _GroupBy.year:
        return '${dt.year}';
    }
  }

  String _monthLabel(int month) {
    if (month < 1 || month > 12) return 'Month';
    return _monthLabels[month - 1];
  }

  bool _matchesFilters(Map<String, dynamic> payment) {
    final createdAt = _createdAt(payment);
    if (createdAt == null) return false;

    final range = _effectiveRange();
    if (range != null) {
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      if (createdAt.isBefore(start) || createdAt.isAfter(end)) return false;
    }

    final method = (payment['method'] ?? '').toString().trim();
    final status = (payment['status'] ?? '').toString().trim();
    if (_method != 'All' && method != _method) return false;
    if (_status != 'All' && status != _status) return false;

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = [
      (payment['paymentNumber'] ?? '').toString(),
      (payment['billNumber'] ?? '').toString(),
      (payment['customerName'] ?? '').toString(),
      method,
      status,
      ((payment['amount'] ?? '')).toString(),
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  DateTimeRange? _effectiveRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_preset) {
      case _SalesPreset.today:
        return DateTimeRange(start: today, end: today);
      case _SalesPreset.last7:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _SalesPreset.last30:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case _SalesPreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today,
        );
      case _SalesPreset.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
      case _SalesPreset.custom:
        return _customRange;
      case _SalesPreset.all:
        return null;
    }
  }

  DateTime? _createdAt(Map<String, dynamic> payment) {
    final value = payment['createdAt'];
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  String _fmt(DateTime? value) {
    if (value == null) return '-';
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '${value.year}-$mm-$dd';
  }

  String _currency(double amount) => 'Rs ${amount.toStringAsFixed(2)}';

  Future<DateTimeRange?> _pickCustomRange() async {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customRange,
    );
  }

  Future<void> _exportCsv(List<Map<String, dynamic>> rows) async {
    final csvRows = <List<dynamic>>[
      [
        'Created At',
        'Payment Number',
        'Bill Number',
        'Customer',
        'Method',
        'Status',
        'Amount',
      ],
      ...rows.map((p) {
        final amount = ((p['amount'] as num?)?.toDouble() ?? 0).toDouble();
        return [
          _fmt(_createdAt(p)),
          (p['paymentNumber'] ?? p['id'] ?? '').toString(),
          (p['billNumber'] ?? '').toString(),
          (p['customerName'] ?? '').toString(),
          (p['method'] ?? '').toString(),
          (p['status'] ?? '').toString(),
          amount.toStringAsFixed(2),
        ];
      }),
    ];

    final csv = const ListToCsvConverter().convert(csvRows);
    final filename =
        'sales_history_${DateTime.now().millisecondsSinceEpoch}.csv';
    final ok = await downloadTextFile(
      filename: filename,
      content: csv,
      mimeType: 'text/csv;charset=utf-8',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'CSV export started' : 'CSV export not supported'),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback? onExport;

  const _HeroHeader({required this.onRefresh, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0B5ED7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Use presets, filters, and exports to understand your mall performance.',
                  style: TextStyle(color: Color(0xFFE7F0FF), height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onExport,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export'),
              ),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String method;
  final String status;
  final int limit;
  final _GroupBy groupBy;
  final _SalesPreset preset;
  final DateTimeRange? customRange;
  final List<String> methodOptions;
  final List<String> statusOptions;
  final VoidCallback onSearchChanged;
  final ValueChanged<_SalesPreset> onPresetChanged;
  final ValueChanged<_GroupBy> onGroupByChanged;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<int> onLimitChanged;
  final VoidCallback onClearAll;

  const _FilterBar({
    required this.searchCtrl,
    required this.method,
    required this.status,
    required this.limit,
    required this.groupBy,
    required this.preset,
    required this.customRange,
    required this.methodOptions,
    required this.statusOptions,
    required this.onSearchChanged,
    required this.onPresetChanged,
    required this.onGroupByChanged,
    required this.onMethodChanged,
    required this.onStatusChanged,
    required this.onLimitChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'payment, bill, customer',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => onSearchChanged(),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final p in _SalesPreset.values)
              ChoiceChip(
                label: Text(_presetLabel(p, customRange)),
                selected: p == preset,
                onSelected: (_) => onPresetChanged(p),
              ),
          ],
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<_GroupBy>(
            initialValue: groupBy,
            decoration: const InputDecoration(
              labelText: 'Group by',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _GroupBy.values
                .map(
                  (g) =>
                      DropdownMenuItem(value: g, child: Text(_groupLabel(g))),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              onGroupByChanged(v);
            },
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: method,
            decoration: const InputDecoration(
              labelText: 'Method',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: methodOptions
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => onMethodChanged(v ?? 'All'),
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: statusOptions
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => onStatusChanged(v ?? 'All'),
          ),
        ),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<int>(
            initialValue: limit,
            decoration: const InputDecoration(
              labelText: 'Load',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 200, child: Text('200')),
              DropdownMenuItem(value: 500, child: Text('500')),
              DropdownMenuItem(value: 1000, child: Text('1000')),
            ],
            onChanged: (v) => onLimitChanged(v ?? 500),
          ),
        ),
        TextButton.icon(
          onPressed: onClearAll,
          icon: const Icon(Icons.clear_all_outlined),
          label: const Text('Clear filters'),
        ),
      ],
    );
  }

  static String _groupLabel(_GroupBy g) {
    switch (g) {
      case _GroupBy.day:
        return 'Day';
      case _GroupBy.week:
        return 'Week';
      case _GroupBy.month:
        return 'Month';
      case _GroupBy.year:
        return 'Year';
    }
  }

  static String _presetLabel(_SalesPreset preset, DateTimeRange? customRange) {
    switch (preset) {
      case _SalesPreset.today:
        return 'Today';
      case _SalesPreset.last7:
        return '7D';
      case _SalesPreset.last30:
        return '30D';
      case _SalesPreset.thisMonth:
        return 'This month';
      case _SalesPreset.thisYear:
        return 'This year';
      case _SalesPreset.custom:
        if (customRange == null) return 'Custom';
        final start = '${customRange.start.month}/${customRange.start.day}';
        final end = '${customRange.end.month}/${customRange.end.day}';
        return '$start-$end';
      case _SalesPreset.all:
        return 'All';
    }
  }
}

class _PaymentsTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final ScrollController vertical;
  final ScrollController horizontal;
  final String Function(double) currency;
  final String Function(DateTime?) fmt;
  final DateTime? Function(Map<String, dynamic>) createdAt;

  const _PaymentsTable({
    required this.rows,
    required this.vertical,
    required this.horizontal,
    required this.currency,
    required this.fmt,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('No payments found for your filters yet.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Container(
          height: 560,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4EBF3)),
          ),
          child: Scrollbar(
            controller: vertical,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: vertical,
              padding: const EdgeInsets.all(12),
              child: Scrollbar(
                controller: horizontal,
                thumbVisibility: true,
                notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1260),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFEFF5FC),
                      ),
                      columns: const [
                        DataColumn(label: Text('Created')),
                        DataColumn(label: Text('Payment #')),
                        DataColumn(label: Text('Bill #')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Method')),
                        DataColumn(label: Text('Status')),
                        DataColumn(
                          label: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Amount'),
                          ),
                          numeric: true,
                        ),
                      ],
                      rows: rows.take(1000).map((p) {
                        final amount = ((p['amount'] as num?)?.toDouble() ?? 0)
                            .toDouble();
                        return DataRow(
                          cells: [
                            DataCell(Text(fmt(createdAt(p)))),
                            DataCell(
                              Text(
                                (p['paymentNumber'] ?? p['id'] ?? '')
                                    .toString(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                (p['billNumber'] ?? '').toString(),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            DataCell(
                              Text((p['customerName'] ?? '').toString()),
                            ),
                            DataCell(
                              _Pill(label: (p['method'] ?? '').toString()),
                            ),
                            DataCell(
                              _StatusPill(
                                value: (p['status'] ?? '').toString(),
                              ),
                            ),
                            DataCell(
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  currency(amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  const _Pill({
    required this.label,
    this.background = const Color(0xFFF1F5F9),
    this.border = const Color(0xFFE2E8F0),
    this.foreground = const Color(0xFF334155),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label.trim().isEmpty ? '-' : label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String value;

  const _StatusPill({required this.value});

  @override
  Widget build(BuildContext context) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('success') || normalized.contains('paid')) {
      return const _Pill(
        label: 'Success',
        background: Color(0xFFDFF7ED),
        border: Color(0xFFBDEBD6),
        foreground: Color(0xFF0F8A4B),
      );
    }
    if (normalized.contains('fail') || normalized.contains('error')) {
      return const _Pill(
        label: 'Failed',
        background: Color(0xFFFFE8EA),
        border: Color(0xFFFFC9CF),
        foreground: Color(0xFFB42318),
      );
    }
    if (normalized.contains('pending')) {
      return const _Pill(
        label: 'Pending',
        background: Color(0xFFFFF4DF),
        border: Color(0xFFFFE1AE),
        foreground: Color(0xFF9A5B00),
      );
    }
    return _Pill(label: value.trim().isEmpty ? '-' : value);
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Color(0xFF5F6C7C))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsolidatedSummaryCard extends StatelessWidget {
  final _GroupBy groupBy;
  final _Bucket? topBucket;
  final int totalBuckets;
  final String Function(double) currency;

  const _ConsolidatedSummaryCard({
    required this.groupBy,
    required this.topBucket,
    required this.totalBuckets,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consolidated Summary (${_groupLabel(groupBy)})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Buckets loaded', value: '$totalBuckets'),
          _SummaryRow(label: 'Top bucket', value: topBucket?.label ?? '-'),
          _SummaryRow(
            label: 'Top bucket sales',
            value: topBucket == null ? '-' : currency(topBucket!.sales),
          ),
          _SummaryRow(
            label: 'Top bucket orders',
            value: topBucket == null ? '-' : '${topBucket!.orders}',
          ),
          const SizedBox(height: 8),
          const Text(
            'Tip: Use Group by + presets to compare performance quickly.',
            style: TextStyle(color: Color(0xFF5F6C7C)),
          ),
        ],
      ),
    );
  }

  static String _groupLabel(_GroupBy g) {
    switch (g) {
      case _GroupBy.day:
        return 'Day';
      case _GroupBy.week:
        return 'Week';
      case _GroupBy.month:
        return 'Month';
      case _GroupBy.year:
        return 'Year';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5F6C7C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _TrendBucketsCard extends StatelessWidget {
  final _GroupBy groupBy;
  final List<_Bucket> buckets;
  final String Function(double) currency;

  const _TrendBucketsCard({
    required this.groupBy,
    required this.buckets,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend (${_groupLabel(groupBy)})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const SizedBox(
              height: 180,
              child: Center(child: Text('No data to chart yet')),
            ),
          ],
        ),
      );
    }

    final maxSales = buckets.fold<double>(0, (m, b) => math.max(m, b.sales));
    final safeMax = maxSales <= 0 ? 1.0 : maxSales;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend (${_groupLabel(groupBy)})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...buckets.map((b) {
            final pct = b.sales / safeMax;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      b.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct.isFinite ? pct : 0,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFEFF5FC),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF0B5ED7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: Text(
                      currency(b.sales),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _groupLabel(_GroupBy g) {
    switch (g) {
      case _GroupBy.day:
        return 'Day';
      case _GroupBy.week:
        return 'Week';
      case _GroupBy.month:
        return 'Month';
      case _GroupBy.year:
        return 'Year';
    }
  }
}

class _Bucket {
  final String key;
  final String label;
  final int orders;
  final double sales;

  const _Bucket({
    required this.key,
    required this.label,
    required this.orders,
    required this.sales,
  });
}

class _BucketAccumulator {
  final String label;
  int orders = 0;
  double sales = 0;

  _BucketAccumulator(this.label);
}
