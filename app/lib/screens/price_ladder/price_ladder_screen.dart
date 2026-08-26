import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';

class PriceLadderScreen extends ConsumerWidget {
  const PriceLadderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(calculationResultProvider);
    final instrument = ref.watch(instrumentSpecProvider);
    final currentPrice = ref.watch(currentPriceProvider);

    if (result == null || result.levels.isEmpty) {
      return const SafeScaffold(
        title: 'Price Ladder',
        body: Center(child: Text('No data available')),
      );
    }

    return SafeScaffold(
      title: 'Price Ladder',
      body: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(Colors.blue, 'Grid Level'),
                const SizedBox(width: 16),
                _legendItem(Colors.green, 'Avg Entry'),
                const SizedBox(width: 16),
                _legendItem(Colors.orange, 'Basket BE'),
                if (result.estimatedStopOutPrice != null) ...[
                  const SizedBox(width: 16),
                  _legendItem(Colors.red, 'Est. Stop-out'),
                ],
              ],
            ),
          ),

          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PriceLadderChart(
                levels: result.levels,
                averageEntry: result.averageEntryPrice,
                breakeven: result.basketBreakevenPrice,
                stopOut: result.estimatedStopOutPrice,
                currentPrice: currentPrice,
                instrument: instrument,
              ),
            ),
          ),

          // Selected level details
          _LevelDetailsPanel(levels: result.levels),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _PriceLadderChart extends StatelessWidget {
  final List<GridLevel> levels;
  final double averageEntry;
  final double breakeven;
  final double? stopOut;
  final double currentPrice;
  final InstrumentSpec instrument;

  const _PriceLadderChart({
    required this.levels,
    required this.averageEntry,
    required this.breakeven,
    this.stopOut,
    required this.currentPrice,
    required this.instrument,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate price range
    final allPrices = [
      ...levels.map((l) => l.entryPrice),
      averageEntry,
      breakeven,
      if (stopOut != null) stopOut!,
    ];
    final minPrice = allPrices.reduce((a, b) => a < b ? a : b);
    final maxPrice = allPrices.reduce((a, b) => a > b ? a : b);
    final padding = (maxPrice - minPrice) * 0.15;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxPrice - minPrice) / 10,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              getTitlesWidget: (value, meta) {
                final price = value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    price.toStringAsFixed(instrument.digits > 2 ? 2 : instrument.digits),
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minPrice - padding,
        maxY: maxPrice + padding,
        lineBarsData: [
          // Grid levels as horizontal lines
          for (int i = 0; i < levels.length; i++)
            LineChartBarData(
              spots: [
                FlSpot(0, levels[i].entryPrice),
                FlSpot(1, levels[i].entryPrice),
              ],
              isCurved: false,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  );
                },
              ),
            ),
          // Average entry line
          LineChartBarData(
            spots: [
              FlSpot(0, averageEntry),
              FlSpot(1, averageEntry),
            ],
            isCurved: false,
            color: Colors.green,
            barWidth: 2,
            dashArray: [8, 4],
            dotData: const FlDotData(show: false),
          ),
          // Breakeven line
          LineChartBarData(
            spots: [
              FlSpot(0, breakeven),
              FlSpot(1, breakeven),
            ],
            isCurved: false,
            color: Colors.orange,
            barWidth: 2,
            dashArray: [4, 4],
            dotData: const FlDotData(show: false),
          ),
          // Stop-out line (if exists)
          if (stopOut != null)
            LineChartBarData(
              spots: [
                FlSpot(0, stopOut!),
                FlSpot(1, stopOut!),
              ],
              isCurved: false,
              color: Colors.red,
              barWidth: 2,
              dashArray: [2, 2],
              dotData: const FlDotData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final levelIndex = levels.indexWhere(
                  (l) => (l.entryPrice - spot.y).abs() < 0.01,
                );
                if (levelIndex >= 0) {
                  final level = levels[levelIndex];
                  return LineTooltipItem(
                    'L${level.index}: ${level.roundedLot.toStringAsFixed(2)} lots\n'
                    '@ ${level.entryPrice.toStringAsFixed(instrument.digits > 2 ? 2 : instrument.digits)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return null;
              }).whereType<LineTooltipItem>().toList();
            },
          ),
        ),
      ),
    );
  }
}

class _LevelDetailsPanel extends StatefulWidget {
  final List<GridLevel> levels;

  const _LevelDetailsPanel({required this.levels});

  @override
  State<_LevelDetailsPanel> createState() => _LevelDetailsPanelState();
}

class _LevelDetailsPanelState extends State<_LevelDetailsPanel> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: _selectedIndex == null
          ? Center(
              child: Text(
                'Tap a level on the chart to see details',
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          : _buildDetail(widget.levels[_selectedIndex!]),
    );
  }

  Widget _buildDetail(GridLevel level) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _detailColumn('Level', '${level.index}'),
            _detailColumn('Lot', level.roundedLot.toStringAsFixed(2)),
            _detailColumn('Entry', level.entryPrice.toStringAsFixed(2)),
            _detailColumn('Cum. Lot', level.cumulativeLot.toStringAsFixed(2)),
            _detailColumn('Margin', '\$${level.requiredMargin.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _detailColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
