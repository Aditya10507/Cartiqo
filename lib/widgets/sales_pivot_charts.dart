import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Pivot-like chart pack for sales dashboards.
///
/// Designed to be fed with already-aggregated buckets to keep Firestore reads
/// unchanged and render fast on web.
class SalesPivotCharts extends StatefulWidget {
  final String title;
  final List<SalesBucketPoint> points; // chronological
  final Map<String, double> methodTotals; // raw methods (or normalized)
  final String Function(double) currency;

  const SalesPivotCharts({
    super.key,
    required this.title,
    required this.points,
    required this.methodTotals,
    required this.currency,
  });

  @override
  State<SalesPivotCharts> createState() => _SalesPivotChartsState();
}

class _SalesPivotChartsState extends State<SalesPivotCharts> {
  _PivotMetric _metric = _PivotMetric.sales;

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final hasData = points.isNotEmpty;
    final theme = Theme.of(context);

    final metricValue = _metric == _PivotMetric.sales
        ? points.fold<double>(0, (m, p) => math.max(m, p.sales))
        : points.fold<double>(0, (m, p) => math.max(m, p.orders.toDouble()));
    final safeMax = metricValue <= 0 ? 1.0 : metricValue;

    final series = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(
          i.toDouble(),
          _metric == _PivotMetric.sales ? points[i].sales : points[i].orders.toDouble(),
        ),
    ];

    final palette = const _PivotPalette();

    final normalized = _normalizeMethods(widget.methodTotals);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              SegmentedButton<_PivotMetric>(
                segments: const [
                  ButtonSegment(value: _PivotMetric.sales, label: Text('Sales')),
                  ButtonSegment(value: _PivotMetric.orders, label: Text('Orders')),
                ],
                selected: {_metric},
                onSelectionChanged: (value) => setState(() => _metric = value.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(theme.textTheme.labelMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxWidth < 920;
              if (!hasData) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: Text('No data to chart yet')),
                );
              }

              final trend = _TrendCard(
                points: points,
                safeMax: safeMax,
                series: series,
                metric: _metric,
                currency: widget.currency,
                palette: palette,
              );
              final donut = _DonutCard(
                normalizedTotals: normalized,
                palette: palette,
                currency: widget.currency,
              );

              if (compact) {
                return Column(
                  children: [
                    SizedBox(height: 260, child: trend),
                    const SizedBox(height: 12),
                    SizedBox(height: 240, child: donut),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 7, child: SizedBox(height: 280, child: trend)),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: SizedBox(height: 280, child: donut)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _PivotMetric { sales, orders }

class SalesBucketPoint {
  final String label;
  final int orders;
  final double sales;

  const SalesBucketPoint({
    required this.label,
    required this.orders,
    required this.sales,
  });
}

class _PivotPalette {
  const _PivotPalette();

  final Color blue = const Color(0xFF0B5ED7);
  final Color green = const Color(0xFF12B886);
  final Color amber = const Color(0xFFFF9F1C);
  final Color violet = const Color(0xFF7C3AED);

  Color byIndex(int i) {
    switch (i % 4) {
      case 0:
        return blue;
      case 1:
        return green;
      case 2:
        return amber;
      default:
        return violet;
    }
  }
}

class _TrendCard extends StatelessWidget {
  final List<SalesBucketPoint> points;
  final double safeMax;
  final List<FlSpot> series;
  final _PivotMetric metric;
  final String Function(double) currency;
  final _PivotPalette palette;

  const _TrendCard({
    required this.points,
    required this.safeMax,
    required this.series,
    required this.metric,
    required this.currency,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final primary = metric == _PivotMetric.sales ? palette.green : palette.blue;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: safeMax * 1.12,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: const Color(0xFFE8EEF7),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: safeMax / 4,
                  getTitlesWidget: (v, meta) {
                    if (v == 0) return const SizedBox.shrink();
                    if (metric == _PivotMetric.orders) {
                      return Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5F6C7C),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Text(
                      _compactRupees(v),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5F6C7C),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: _bottomInterval(points.length),
                  getTitlesWidget: (v, meta) {
                    final idx = v.round();
                    if (idx < 0 || idx >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _shortBucket(points[idx].label),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5F6C7C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.22,
                barWidth: 3,
                color: primary,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primary.withValues(alpha: 0.22),
                      primary.withValues(alpha: 0.02),
                    ],
                  ),
                ),
                spots: series,
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                getTooltipItems: (items) {
                  return items.map((item) {
                    final idx = item.x.round();
                    final p = points[idx];
                    final v = metric == _PivotMetric.sales
                        ? currency(p.sales)
                        : '${p.orders}';
                    return LineTooltipItem(
                      '${p.label}\n$v',
                      const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1220),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
          duration: const Duration(milliseconds: 220),
        ),
      ),
    );
  }

  static double _bottomInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 28) return 4;
    return 6;
  }

  static String _shortBucket(String label) {
    // Make x-axis labels compact: show "Mar" for months, "2026" for year, else day.
    if (label.length <= 10) return label;
    // Weekly range like "2026-03-01 to 2026-03-07"
    if (label.contains(' to ')) return label.split(' ').first;
    return label;
  }
}

class _DonutCard extends StatelessWidget {
  final Map<String, double> normalizedTotals;
  final _PivotPalette palette;
  final String Function(double) currency;

  const _DonutCard({
    required this.normalizedTotals,
    required this.palette,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final entries = normalizedTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (t, e) => t + e.value);

    if (entries.isEmpty || total <= 0) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EEF7)),
        ),
        child: const Center(child: Text('No payment split yet')),
      );
    }

    final sections = <PieChartSectionData>[
      for (var i = 0; i < entries.length; i++)
        PieChartSectionData(
          value: entries[i].value,
          showTitle: false,
          color: palette.byIndex(i),
          radius: 44,
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment mix',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 34,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                          ),
                          duration: const Duration(milliseconds: 220),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5F6C7C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              currency(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final pct = (entries[i].value / total) * 100;
                        return Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: palette.byIndex(i),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entries[i].key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF243041),
                                ),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5F6C7C),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, double> _normalizeMethods(Map<String, double> raw) {
  final out = <String, double>{
    'Cash': 0,
    'UPI': 0,
    'Card': 0,
    'Other': 0,
  };

  for (final entry in raw.entries) {
    final key = entry.key.toString().trim().toUpperCase();
    if (key.isEmpty) continue;
    if (key.contains('CASH')) {
      out['Cash'] = (out['Cash'] ?? 0) + entry.value;
    } else if (key.contains('UPI')) {
      out['UPI'] = (out['UPI'] ?? 0) + entry.value;
    } else if (key.contains('CARD')) {
      out['Card'] = (out['Card'] ?? 0) + entry.value;
    } else {
      out['Other'] = (out['Other'] ?? 0) + entry.value;
    }
  }

  out.removeWhere((k, v) => v <= 0);
  return out;
}

String _compactRupees(double v) {
  if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
  return '₹${v.toStringAsFixed(0)}';
}
