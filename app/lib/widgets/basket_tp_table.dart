import 'package:flutter/material.dart';
import 'package:grid_engine/grid_engine.dart';

/// Quick-reference table showing basket breakeven and target P/L prices.
///
/// Displays a compact table with common target P/L milestones.
class BasketTpTable extends StatelessWidget {
  final List<GridLevel> levels;
  final Direction direction;
  final InstrumentSpec instrument;
  final ExecutionSpec execution;
  final List<double> targets;

  const BasketTpTable({
    super.key,
    required this.levels,
    required this.direction,
    required this.instrument,
    required this.execution,
    this.targets = const [0, 50, 100, 200],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basket Take-Profit',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
              },
              children: [
                // Header
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Target P/L',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Close Price',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...targets.map((target) {
                  final price = PnlCalculator.priceForTargetPnl(
                    levels: levels,
                    targetPnl: target,
                    direction: direction,
                    instrument: instrument,
                    execution: execution,
                  );

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          target == 0 ? 'Breakeven' : '\$${target.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: target == 0 ? FontWeight.bold : FontWeight.normal,
                            color: target == 0 ? Colors.blue : null,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '\$${price.toStringAsFixed(instrument.digits > 2 ? 2 : instrument.digits)}',
                          style: TextStyle(
                            fontWeight: target == 0 ? FontWeight.bold : FontWeight.normal,
                            color: target == 0 ? Colors.blue : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
