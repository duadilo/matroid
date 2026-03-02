import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

/// Monthly revenue (Jan–Dec) in thousands.
const _monthlyRevenue = [
  12.0, 14.5, 13.8, 16.2, 18.0, 21.3, 19.7, 22.5, 24.0, 23.1, 26.4, 28.0,
];

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Quarterly sales by region.
const _regions = ['North', 'South', 'East', 'West'];
const _quarterlyByRegion = [
  [42.0, 38.0, 55.0, 30.0], // Q1
  [48.0, 42.0, 50.0, 35.0], // Q2
  [52.0, 45.0, 60.0, 40.0], // Q3
  [58.0, 50.0, 65.0, 45.0], // Q4
];

/// Market share breakdown (%).
const _marketValues = [35.0, 25.0, 20.0, 12.0, 8.0];

/// Height vs weight scatter data.
const _heightWeight = [
  (160.0, 55.0), (165.0, 62.0), (170.0, 68.0), (172.0, 65.0),
  (175.0, 72.0), (178.0, 78.0), (180.0, 80.0), (182.0, 75.0),
  (185.0, 85.0), (190.0, 90.0), (168.0, 60.0), (174.0, 70.0),
];

/// Radar: skill assessment (5 axes).
const _skillLabels = ['Speed', 'Power', 'Technique', 'Stamina', 'Agility'];
const _skillValues = [0.8, 0.65, 0.9, 0.7, 0.85];

/// Stacked bar: product category breakdown by quarter.
const _stackCategories = ['Electronics', 'Clothing', 'Food'];
const _stackByQuarter = [
  [30.0, 20.0, 15.0], // Q1
  [35.0, 22.0, 18.0], // Q2
  [40.0, 25.0, 20.0], // Q3
  [45.0, 28.0, 22.0], // Q4
];

// ---------------------------------------------------------------------------
// ChartsContent (body-only — no Scaffold)
// ---------------------------------------------------------------------------

class ChartsContent extends StatelessWidget {
  const ChartsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [Chip(label: Text(l10n.chartsTitle))],
          ),
        ),
        const Divider(height: 1),
        // Body
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth >= 700 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossCount,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: const [
                  _ChartCard(title: 'Monthly Revenue', child: _LineChart()),
                  _ChartCard(title: 'Quarterly Sales by Region', child: _BarChart()),
                  _ChartCard(title: 'Market Share', child: _PieChart()),
                  _ChartCard(title: 'Height vs Weight', child: _ScatterChart()),
                  _ChartCard(title: 'Skill Assessment', child: _RadarChart()),
                  _ChartCard(title: 'Product Breakdown', child: _StackedBarChart()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card wrapper
// ---------------------------------------------------------------------------

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Line Chart — Monthly revenue
// ---------------------------------------------------------------------------

class _LineChart extends StatelessWidget {
  const _LineChart();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= _months.length) return const SizedBox.shrink();
                return Text(_months[i], style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < _monthlyRevenue.length; i++)
                FlSpot(i.toDouble(), _monthlyRevenue[i]),
            ],
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withAlpha(40),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Bar Chart — Quarterly sales by region
// ---------------------------------------------------------------------------

class _BarChart extends StatelessWidget {
  const _BarChart();

  static const _barColors = [
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final labels = ['Q1', 'Q2', 'Q3', 'Q4'];
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(labels[i], style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var q = 0; q < 4; q++)
            BarChartGroupData(
              x: q,
              barRods: [
                for (var r = 0; r < _regions.length; r++)
                  BarChartRodData(
                    toY: _quarterlyByRegion[q][r],
                    color: _barColors[r],
                    width: 8,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Pie Chart — Market share
// ---------------------------------------------------------------------------

class _PieChart extends StatelessWidget {
  const _PieChart();

  static const _pieColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.amber,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: [
          for (var i = 0; i < _marketValues.length; i++)
            PieChartSectionData(
              value: _marketValues[i],
              title: '${_marketValues[i].toInt()}%',
              color: _pieColors[i],
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Scatter Plot — Height vs Weight
// ---------------------------------------------------------------------------

class _ScatterChart extends StatelessWidget {
  const _ScatterChart();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return ScatterChart(
      ScatterChartData(
        scatterSpots: [
          for (final (h, w) in _heightWeight)
            ScatterSpot(h, w, dotPainter: FlDotCirclePainter(
              radius: 5,
              color: color,
            )),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 155,
        maxX: 195,
        minY: 50,
        maxY: 95,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Radar Chart — Skill assessment
// ---------------------------------------------------------------------------

class _RadarChart extends StatelessWidget {
  const _RadarChart();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return RadarChart(
      RadarChartData(
        radarTouchData: RadarTouchData(enabled: false),
        dataSets: [
          RadarDataSet(
            dataEntries: [
              for (final v in _skillValues) RadarEntry(value: v),
            ],
            borderColor: color,
            fillColor: color.withAlpha(60),
            borderWidth: 2,
          ),
        ],
        getTitle: (index, _) => RadarChartTitle(
          text: _skillLabels[index],
        ),
        titlePositionPercentageOffset: 0.15,
        tickCount: 4,
        ticksTextStyle: const TextStyle(fontSize: 0), // hide tick labels
        tickBorderData: BorderSide(color: Colors.grey.withAlpha(80)),
        gridBorderData: BorderSide(color: Colors.grey.withAlpha(80)),
        radarBorderData: BorderSide.none,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Stacked Bar Chart — Product category breakdown
// ---------------------------------------------------------------------------

class _StackedBarChart extends StatelessWidget {
  const _StackedBarChart();

  static const _stackColors = [
    Colors.indigo,
    Colors.teal,
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final labels = ['Q1', 'Q2', 'Q3', 'Q4'];
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(labels[i], style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var q = 0; q < 4; q++)
            BarChartGroupData(
              x: q,
              barRods: [
                BarChartRodData(
                  toY: _stackByQuarter[q].fold(0.0, (a, b) => a + b),
                  rodStackItems: [
                    for (var c = 0; c < _stackCategories.length; c++)
                      BarChartRodStackItem(
                        _stackByQuarter[q].take(c).fold(0.0, (a, b) => a + b),
                        _stackByQuarter[q].take(c + 1).fold(0.0, (a, b) => a + b),
                        _stackColors[c],
                      ),
                  ],
                  width: 20,
                  borderRadius: BorderRadius.zero,
                  color: Colors.transparent,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
