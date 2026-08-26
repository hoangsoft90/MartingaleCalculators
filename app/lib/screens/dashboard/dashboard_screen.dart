import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';
import '../price_ladder/price_ladder_screen.dart';
import '../what_if/what_if_screen.dart';
import '../reverse_mode/reverse_mode_screen.dart';
import '../share/share_screen.dart';
import '../saved_strategies/saved_strategies_screen.dart';
import '../quick_calculator/quick_calculator_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(calculationResultProvider);

    if (result == null) {
      return const SafeScaffold(
        title: 'Risk Dashboard',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strategy = ref.watch(strategySpecProvider);
    final instrument = ref.watch(instrumentSpecProvider);

    return SafeScaffold(
      title: 'Risk Dashboard',
      actions: [
        // Edit button - go back to calculator
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Edit parameters',
          onPressed: () {
            AppNavigation.pushReplacement(context, const QuickCalculatorScreen());
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pre-flight warnings banner
          if (result.constraintResults.any((r) => !r.passed))
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some constraints are violated. Review results below.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // 5 Key Metrics
          _buildMetricCard(
            context,
            'Survivable Levels',
            '${result.survivableLevels} / ${strategy.levels}',
            Icons.shield,
            result.survivableLevels >= strategy.levels
                ? Colors.green
                : Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            context,
            'Max Drawdown',
            '${result.maxDrawdownPercent.toStringAsFixed(1)}%',
            Icons.trending_down,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            context,
            'Estimated Stop-out',
            result.estimatedStopOutPrice != null
                ? '\$${result.estimatedStopOutPrice!.toStringAsFixed(2)}'
                : 'Not reached',
            Icons.money_off,
            result.estimatedStopOutPrice != null ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            context,
            'Basket Breakeven',
            '\$${result.basketBreakevenPrice.toStringAsFixed(2)}',
            Icons.balance,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            context,
            'Rebind Distance',
            '${result.rebindDistanceToBreakeven.toStringAsFixed(2)} ${instrument.symbol == "XAUUSD" ? "\$" : "pips"}',
            Icons.straighten,
            Colors.purple,
          ),
          const SizedBox(height: 8),
          _buildMetricCard(
            context,
            'Total Exposure',
            '${result.totalExposureLots.toStringAsFixed(2)} lots',
            Icons.account_balance_wallet,
            Colors.teal,
          ),
          const SizedBox(height: 16),

          // Constraint Results
          if (result.constraintResults.isNotEmpty) ...[
            Text(
              'Constraint Check',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...result.constraintResults.map((cr) => ListTile(
              leading: Icon(
                cr.passed ? Icons.check_circle : Icons.cancel,
                color: cr.passed ? Colors.green : Colors.red,
              ),
              title: Text(cr.constraintName),
              subtitle: Text(cr.detailMessage),
              dense: true,
            )),
            const Divider(),
          ],

          // Assumptions Panel
          ExpansionTile(
            title: const Text('Assumptions Used'),
            children: result.assumptionsUsed
                .map((a) => ListTile(
                      leading: const Icon(Icons.info_outline, size: 16),
                      title: Text(a, style: const TextStyle(fontSize: 13)),
                      dense: true,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Grid Levels Table
          Text(
            'Grid Levels',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildLevelsTable(context, result.levels),

          const SizedBox(height: 24),

          // Navigation buttons - 2x2 grid
          Row(
            children: [
              Expanded(
                child: _NavButton(
                  icon: Icons.linear_scale,
                  label: 'Price Ladder',
                  onTap: () => AppNavigation.push(context, const PriceLadderScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavButton(
                  icon: Icons.tune,
                  label: 'What-if',
                  onTap: () => AppNavigation.push(context, const WhatIfScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NavButton(
                  icon: Icons.flip,
                  label: 'Reverse',
                  onTap: () => AppNavigation.push(context, const ReverseModeScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => AppNavigation.push(context, const ShareScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _NavButton(
            icon: Icons.bookmark,
            label: 'Saved Strategies',
            onTap: () => AppNavigation.push(context, const SavedStrategiesScreen()),
            fullWidth: true,
          ),
          const SizedBox(height: 24),

          // Disclaimer
          Text(
            'Analytical/educational tool. Not financial advice. Actual broker outcome may differ.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
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

  Widget _buildLevelsTable(BuildContext context, List levels) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Level')),
            DataColumn(label: Text('Lot')),
            DataColumn(label: Text('Entry Price')),
            DataColumn(label: Text('Cum. Lot')),
            DataColumn(label: Text('Margin')),
          ],
          rows: levels.map((level) {
            return DataRow(cells: [
              DataCell(Text('${level.index}')),
              DataCell(Text(level.roundedLot.toStringAsFixed(2))),
              DataCell(Text(level.entryPrice.toStringAsFixed(
                level.entryPrice > 100 ? 2 : 5,
              ))),
              DataCell(Text(level.cumulativeLot.toStringAsFixed(2))),
              DataCell(Text('\$${level.requiredMargin.toStringAsFixed(2)}')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

/// Navigation button widget
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
