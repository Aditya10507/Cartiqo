import 'package:flutter/material.dart';

import '../providers/mall_manager_provider.dart';
import '../services/csv_service.dart';
import '../services/file_download_service.dart';
import 'sales_pivot_charts.dart';

enum _SalesPeriodPreset { all, today, week, month, year, custom }

enum _SalesGroupBy { day, week, month, year }

class ManagerSalesDashboardPanel extends StatefulWidget {
  final MallManagerProvider provider;

  const ManagerSalesDashboardPanel({super.key, required this.provider});

  @override
  State<ManagerSalesDashboardPanel> createState() =>
      _ManagerSalesDashboardPanelState();
}

class _ManagerSalesDashboardPanelState
    extends State<ManagerSalesDashboardPanel> {
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

  _SalesPeriodPreset _periodPreset = _SalesPeriodPreset.all;
  _SalesGroupBy _groupBy = _SalesGroupBy.day;
  String _methodFilter = 'All';
  String _statusFilter = 'All';
  DateTimeRange? _customRange;
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sales Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Refresh sales',
                onPressed: () {
                  setState(() => _refreshNonce++);
                  // Force a one-time read so errors surface immediately.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing sales history...'),
                    ),
                  );
                  widget.provider.watchMallSalesPayments().first.catchError(
                    (_) => const <Map<String, dynamic>>[],
                  );
                },
                icon: const Icon(Icons.refresh_outlined),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Track live daily, weekly, monthly, yearly, and total sales with portal filters, grouped analysis, and CSV export.',
            style: TextStyle(color: Color(0xFF5F6C7C)),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            key: ValueKey(_refreshNonce),
            stream: widget.provider.watchMallSalesPayments(),
            builder: (context, snapshot) {
              final payments = snapshot.data ?? const <Map<String, dynamic>>[];
              final availableMethods = <String>{
                'All',
                ...payments
                    .map(
                      (payment) => (payment['method'] ?? '').toString().trim(),
                    )
                    .where((value) => value.isNotEmpty),
              }.toList();
              final availableStatuses = <String>{
                'All',
                ...payments
                    .map(
                      (payment) => (payment['status'] ?? '').toString().trim(),
                    )
                    .where((value) => value.isNotEmpty),
              }.toList();
              final methodFiltered = payments
                  .where(_matchesMethodAndStatus)
                  .toList();
              final visiblePayments =
                  methodFiltered.where(_matchesSelectedPeriod).toList()..sort(
                    (a, b) => (_readCreatedAt(b) ?? DateTime(2000)).compareTo(
                      _readCreatedAt(a) ?? DateTime(2000),
                    ),
                  );
              final groupedRows = _buildGroupedRows(visiblePayments);
              final summary = _buildSummary(methodFiltered);
              final chartRows = [...groupedRows]
                ..sort((a, b) => a.key.compareTo(b.key));
              final points = chartRows
                  .map(
                    (row) => SalesBucketPoint(
                      label: row.label,
                      orders: row.orders,
                      sales: row.sales,
                    ),
                  )
                  .toList();
              final methodTotals = <String, double>{
                'CASH': chartRows.fold<double>(
                  0,
                  (t, row) => t + row.cashSales,
                ),
                'CARD': chartRows.fold<double>(
                  0,
                  (t, row) => t + row.cardSales,
                ),
                'UPI': chartRows.fold<double>(
                  0,
                  (t, row) => t + row.upiSales,
                ),
                'OTHER': chartRows.fold<double>(
                  0,
                  (t, row) => t + row.otherSales,
                ),
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControls(
                    context,
                    payments: payments,
                    availableMethods: availableMethods,
                    availableStatuses: availableStatuses,
                    methodFiltered: methodFiltered,
                    visiblePayments: visiblePayments,
                    groupedRows: groupedRows,
                    summary: summary,
                  ),
                  if (_periodPreset == _SalesPeriodPreset.custom &&
                      _customRange != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Custom range: ${_formatDate(_customRange!.start)} to ${_formatDate(_customRange!.end)}',
                      style: const TextStyle(
                        color: Color(0xFF5F6C7C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildMetricGrid(summary),
                  const SizedBox(height: 16),
                  SalesPivotCharts(
                    title: 'Pivot charts (${_groupLabel(_groupBy)})',
                    points: points,
                    methodTotals: methodTotals,
                    currency: _formatCurrency,
                  ),
                  const SizedBox(height: 16),
                  _buildAnalysisChips(summary),
                  const SizedBox(height: 16),
                  _buildTableArea(payments: payments, groupedRows: groupedRows),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context, {
    required List<Map<String, dynamic>> payments,
    required List<String> availableMethods,
    required List<String> availableStatuses,
    required List<Map<String, dynamic>> methodFiltered,
    required List<Map<String, dynamic>> visiblePayments,
    required List<_GroupedSalesRow> groupedRows,
    required _SalesSummary summary,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._SalesPeriodPreset.values.map(
          (preset) => ChoiceChip(
            label: Text(_periodLabel(preset)),
            selected: _periodPreset == preset,
            onSelected: (_) async {
              if (preset == _SalesPeriodPreset.custom) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _customRange,
                );
                if (range == null) return;
                setState(() {
                  _customRange = range;
                  _periodPreset = preset;
                });
                return;
              }
              setState(() => _periodPreset = preset);
            },
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: _methodFilter,
            decoration: const InputDecoration(
              labelText: 'Method',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: availableMethods
                .map(
                  (method) =>
                      DropdownMenuItem(value: method, child: Text(method)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _methodFilter = value);
            },
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: availableStatuses
                .map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _statusFilter = value);
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<_SalesGroupBy>(
            initialValue: _groupBy,
            decoration: const InputDecoration(
              labelText: 'Consolidate By',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _SalesGroupBy.values
                .map(
                  (group) => DropdownMenuItem(
                    value: group,
                    child: Text(_groupLabel(group)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _groupBy = value);
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed: payments.isEmpty
              ? null
              : () => _exportCsv(
                  methodFiltered,
                  visiblePayments,
                  groupedRows,
                  summary,
                ),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  Widget _buildMetricGrid(_SalesSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 960;
        return GridView.count(
          crossAxisCount: compact ? 2 : 5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: compact ? 1.35 : 1.55,
          children: [
            _SalesMetricCard(
              label: 'Daily Sales',
              value: _formatCurrency(summary.dailySales),
              accent: const Color(0xFF0B5ED7),
              icon: Icons.today_outlined,
            ),
            _SalesMetricCard(
              label: 'Weekly Sales',
              value: _formatCurrency(summary.weeklySales),
              accent: const Color(0xFF12B886),
              icon: Icons.date_range_outlined,
            ),
            _SalesMetricCard(
              label: 'Monthly Sales',
              value: _formatCurrency(summary.monthlySales),
              accent: const Color(0xFFFF9F1C),
              icon: Icons.calendar_month_outlined,
            ),
            _SalesMetricCard(
              label: 'Yearly Sales',
              value: _formatCurrency(summary.yearlySales),
              accent: const Color(0xFF7C3AED),
              icon: Icons.insights_outlined,
            ),
            _SalesMetricCard(
              label: 'Total Sales',
              value: _formatCurrency(summary.totalSales),
              accent: const Color(0xFFEF4444),
              icon: Icons.currency_rupee_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalysisChips(_SalesSummary summary) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _AnalysisChip(label: 'Orders', value: '${summary.totalOrders}'),
        _AnalysisChip(
          label: 'Average Order Value',
          value: _formatCurrency(summary.averageOrderValue),
        ),
        _AnalysisChip(
          label: 'Best ${_groupLabel(_groupBy).toLowerCase()}',
          value: summary.bestPeriodLabel,
        ),
        _AnalysisChip(label: 'Top Payment Method', value: summary.topMethod),
      ],
    );
  }

  Widget _buildTableArea({
    required List<Map<String, dynamic>> payments,
    required List<_GroupedSalesRow> groupedRows,
  }) {
    if (payments.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Sales records will appear here after checkouts are saved.',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HintChip(label: 'Scroll down for more periods'),
            _HintChip(label: 'Scroll right for more analysis columns'),
            _HintChip(label: 'CSV export matches the current filtered view'),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 420,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4EBF3)),
          ),
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              padding: const EdgeInsets.all(12),
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1100),
                    child: DataTable(
                      horizontalMargin: 18,
                      columnSpacing: 24,
                      dataRowMinHeight: 68,
                      dataRowMaxHeight: 84,
                      headingRowHeight: 58,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFEFF5FC),
                      ),
                      border: TableBorder(
                        horizontalInside: const BorderSide(
                          color: Color(0xFFDCE6F3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      columns: const [
                        DataColumn(label: Text('Period')),
                        DataColumn(label: Text('Orders')),
                        DataColumn(label: Text('Sales')),
                        DataColumn(label: Text('Avg Order Value')),
                        DataColumn(label: Text('Cash')),
                        DataColumn(label: Text('Card')),
                        DataColumn(label: Text('UPI')),
                        DataColumn(label: Text('Other')),
                      ],
                      rows: groupedRows.isEmpty
                          ? [
                              const DataRow(
                                cells: [
                                  DataCell(Text('No rows found')),
                                  DataCell(Text('-')),
                                  DataCell(Text('-')),
                                  DataCell(Text('-')),
                                  DataCell(Text('-')),
                                  DataCell(Text('-')),
                                  DataCell(Text('-')),
                                  DataCell(Text('-')),
                                ],
                              ),
                            ]
                          : groupedRows.map(_buildDataRow).toList(),
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

  DataRow _buildDataRow(_GroupedSalesRow row) {
    return DataRow(
      cells: [
        DataCell(
          Text(row.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        DataCell(Text('${row.orders}')),
        DataCell(Text(_formatCurrency(row.sales))),
        DataCell(Text(_formatCurrency(row.averageOrderValue))),
        DataCell(Text(_formatCurrency(row.cashSales))),
        DataCell(Text(_formatCurrency(row.cardSales))),
        DataCell(Text(_formatCurrency(row.upiSales))),
        DataCell(Text(_formatCurrency(row.otherSales))),
      ],
    );
  }

  bool _matchesMethodAndStatus(Map<String, dynamic> payment) {
    final method = (payment['method'] ?? '').toString().trim();
    final status = (payment['status'] ?? '').toString().trim();
    final matchesMethod = _methodFilter == 'All' || method == _methodFilter;
    final matchesStatus = _statusFilter == 'All' || status == _statusFilter;
    return matchesMethod && matchesStatus;
  }

  bool _matchesSelectedPeriod(Map<String, dynamic> payment) {
    final createdAt = _readCreatedAt(payment);
    if (createdAt == null) return false;

    final now = DateTime.now();
    switch (_periodPreset) {
      case _SalesPeriodPreset.all:
        return true;
      case _SalesPeriodPreset.today:
        return _isSameDay(createdAt, now);
      case _SalesPeriodPreset.week:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        return !createdAt.isBefore(start);
      case _SalesPeriodPreset.month:
        return createdAt.year == now.year && createdAt.month == now.month;
      case _SalesPeriodPreset.year:
        return createdAt.year == now.year;
      case _SalesPeriodPreset.custom:
        if (_customRange == null) return true;
        final start = DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        );
        final end = DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
          23,
          59,
          59,
        );
        return !createdAt.isBefore(start) && !createdAt.isAfter(end);
    }
  }

  _SalesSummary _buildSummary(List<Map<String, dynamic>> payments) {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    double daily = 0;
    double weekly = 0;
    double monthly = 0;
    double yearly = 0;
    double total = 0;
    final methodTotals = <String, double>{};

    for (final payment in payments) {
      final amount = ((payment['amount'] as num?)?.toDouble() ?? 0);
      final createdAt = _readCreatedAt(payment);
      if (createdAt == null) continue;
      total += amount;

      final method = (payment['method'] ?? 'Other').toString().trim();
      methodTotals[method] = (methodTotals[method] ?? 0) + amount;

      if (_isSameDay(createdAt, now)) {
        daily += amount;
      }
      if (!createdAt.isBefore(weekStart)) {
        weekly += amount;
      }
      if (createdAt.year == now.year && createdAt.month == now.month) {
        monthly += amount;
      }
      if (createdAt.year == now.year) {
        yearly += amount;
      }
    }

    final groupedRows = _buildGroupedRows(payments)
      ..sort((a, b) => b.sales.compareTo(a.sales));

    String topMethod = 'No sales yet';
    if (methodTotals.isNotEmpty) {
      final top = methodTotals.entries.reduce(
        (current, next) => current.value >= next.value ? current : next,
      );
      topMethod = top.key;
    }

    return _SalesSummary(
      dailySales: daily,
      weeklySales: weekly,
      monthlySales: monthly,
      yearlySales: yearly,
      totalSales: total,
      totalOrders: payments.length,
      averageOrderValue: payments.isEmpty ? 0 : total / payments.length,
      bestPeriodLabel: groupedRows.isEmpty
          ? 'No sales yet'
          : groupedRows.first.label,
      topMethod: topMethod,
    );
  }

  List<_GroupedSalesRow> _buildGroupedRows(
    List<Map<String, dynamic>> payments,
  ) {
    final grouped = <String, _GroupedSalesAccumulator>{};

    for (final payment in payments) {
      final createdAt = _readCreatedAt(payment);
      if (createdAt == null) continue;
      final key = _groupKey(createdAt);
      final amount = ((payment['amount'] as num?)?.toDouble() ?? 0);
      final method = (payment['method'] ?? '').toString().trim().toUpperCase();
      final bucket = grouped.putIfAbsent(
        key,
        () => _GroupedSalesAccumulator(label: _groupDisplayLabel(createdAt)),
      );
      bucket.orders += 1;
      bucket.sales += amount;
      if (method.contains('CASH')) {
        bucket.cashSales += amount;
      } else if (method.contains('CARD')) {
        bucket.cardSales += amount;
      } else if (method.contains('UPI')) {
        bucket.upiSales += amount;
      } else {
        bucket.otherSales += amount;
      }
    }

    return grouped.entries
        .map(
          (entry) => _GroupedSalesRow(
            key: entry.key,
            label: entry.value.label,
            orders: entry.value.orders,
            sales: entry.value.sales,
            averageOrderValue: entry.value.orders == 0
                ? 0
                : entry.value.sales / entry.value.orders,
            cashSales: entry.value.cashSales,
            cardSales: entry.value.cardSales,
            upiSales: entry.value.upiSales,
            otherSales: entry.value.otherSales,
          ),
        )
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }

  String _groupKey(DateTime date) {
    switch (_groupBy) {
      case _SalesGroupBy.day:
        return _formatDate(date);
      case _SalesGroupBy.week:
        final start = DateTime(
          date.year,
          date.month,
          date.day,
        ).subtract(Duration(days: date.weekday - 1));
        return _formatDate(start);
      case _SalesGroupBy.month:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case _SalesGroupBy.year:
        return '${date.year}';
    }
  }

  String _groupDisplayLabel(DateTime date) {
    switch (_groupBy) {
      case _SalesGroupBy.day:
        return _formatDate(date);
      case _SalesGroupBy.week:
        final start = DateTime(
          date.year,
          date.month,
          date.day,
        ).subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${_formatDate(start)} to ${_formatDate(end)}';
      case _SalesGroupBy.month:
        return '${_monthLabels[date.month - 1]} ${date.year}';
      case _SalesGroupBy.year:
        return '${date.year}';
    }
  }

  DateTime? _readCreatedAt(Map<String, dynamic> payment) {
    final value = payment['createdAt'];
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _periodLabel(_SalesPeriodPreset preset) {
    switch (preset) {
      case _SalesPeriodPreset.all:
        return 'All';
      case _SalesPeriodPreset.today:
        return 'Today';
      case _SalesPeriodPreset.week:
        return 'This Week';
      case _SalesPeriodPreset.month:
        return 'This Month';
      case _SalesPeriodPreset.year:
        return 'This Year';
      case _SalesPeriodPreset.custom:
        return 'Custom Range';
    }
  }

  String _groupLabel(_SalesGroupBy group) {
    switch (group) {
      case _SalesGroupBy.day:
        return 'Day';
      case _SalesGroupBy.week:
        return 'Week';
      case _SalesGroupBy.month:
        return 'Month';
      case _SalesGroupBy.year:
        return 'Year';
    }
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _formatCurrency(double value) {
    return 'Rs ${value.toStringAsFixed(2)}';
  }

  Future<void> _exportCsv(
    List<Map<String, dynamic>> methodFiltered,
    List<Map<String, dynamic>> visiblePayments,
    List<_GroupedSalesRow> groupedRows,
    _SalesSummary summary,
  ) async {
    final csv = CsvService.exportSalesDashboardToCsv(
      summary: {
        'Daily Sales': _formatCurrency(summary.dailySales),
        'Weekly Sales': _formatCurrency(summary.weeklySales),
        'Monthly Sales': _formatCurrency(summary.monthlySales),
        'Yearly Sales': _formatCurrency(summary.yearlySales),
        'Total Sales': _formatCurrency(summary.totalSales),
        'Orders': '${summary.totalOrders}',
        'Average Order Value': _formatCurrency(summary.averageOrderValue),
        'Best ${_groupLabel(_groupBy)}': summary.bestPeriodLabel,
        'Top Payment Method': summary.topMethod,
        'Method Filter': _methodFilter,
        'Status Filter': _statusFilter,
        'Period Filter': _periodLabel(_periodPreset),
      },
      groupByLabel: _groupLabel(_groupBy),
      groupedRows: groupedRows
          .map(
            (row) => {
              'label': row.label,
              'orders': row.orders,
              'sales': row.sales.toStringAsFixed(2),
              'averageOrderValue': row.averageOrderValue.toStringAsFixed(2),
              'cashSales': row.cashSales.toStringAsFixed(2),
              'cardSales': row.cardSales.toStringAsFixed(2),
              'upiSales': row.upiSales.toStringAsFixed(2),
              'otherSales': row.otherSales.toStringAsFixed(2),
            },
          )
          .toList(),
      paymentRows: visiblePayments
          .map(
            (payment) => {
              'createdAt': _formatDate(
                _readCreatedAt(payment) ?? DateTime.now(),
              ),
              'paymentNumber': (payment['paymentNumber'] ?? '').toString(),
              'billNumber': (payment['billNumber'] ?? '').toString(),
              'customerName': (payment['customerName'] ?? '').toString(),
              'method': (payment['method'] ?? '').toString(),
              'status': (payment['status'] ?? '').toString(),
              'amount': ((payment['amount'] as num?)?.toDouble() ?? 0)
                  .toStringAsFixed(2),
            },
          )
          .toList(),
    );

    final filename =
        'sales_dashboard_${widget.provider.currentMallId ?? 'mall'}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final ok = await downloadTextFile(
      filename: filename,
      content: csv,
      mimeType: 'text/csv;charset=utf-8',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Sales CSV export started'
              : 'CSV download is only supported in web browsers',
        ),
      ),
    );
  }
}

class _SalesMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _SalesMetricCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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

class _AnalysisChip extends StatelessWidget {
  final String label;
  final String value;

  const _AnalysisChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Color(0xFF111827)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;

  const _HintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF47607B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SalesSummary {
  final double dailySales;
  final double weeklySales;
  final double monthlySales;
  final double yearlySales;
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final String bestPeriodLabel;
  final String topMethod;

  const _SalesSummary({
    required this.dailySales,
    required this.weeklySales,
    required this.monthlySales,
    required this.yearlySales,
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.bestPeriodLabel,
    required this.topMethod,
  });
}

class _GroupedSalesAccumulator {
  final String label;
  int orders = 0;
  double sales = 0;
  double cashSales = 0;
  double cardSales = 0;
  double upiSales = 0;
  double otherSales = 0;

  _GroupedSalesAccumulator({required this.label});
}

class _GroupedSalesRow {
  final String key;
  final String label;
  final int orders;
  final double sales;
  final double averageOrderValue;
  final double cashSales;
  final double cardSales;
  final double upiSales;
  final double otherSales;

  const _GroupedSalesRow({
    required this.key,
    required this.label,
    required this.orders,
    required this.sales,
    required this.averageOrderValue,
    required this.cashSales,
    required this.cardSales,
    required this.upiSales,
    required this.otherSales,
  });
}
