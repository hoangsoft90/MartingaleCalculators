import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';

class WhatIfScreen extends ConsumerStatefulWidget {
  const WhatIfScreen({super.key});

  @override
  ConsumerState<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends ConsumerState<WhatIfScreen> {
  late double _sliderValue;
  late double _currentPrice;
  bool _inspectorVisible = false;
  final _inspectorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPrice = ref.read(currentPriceProvider);
    _sliderValue = _currentPrice;
  }

  @override
  void dispose() {
    _inspectorController.dispose();
    super.dispose();
  }

  ScenarioPoint _calculateScenario(double price) {
    final strategy = ref.read(strategySpecProvider);
    final instrument = ref.read(instrumentSpecProvider);
    final execution = ref.read(executionSpecProvider);
    final account = ref.read(accountSpecProvider);

    final levels = GridBuilder.build(
      strategy: strategy,
      instrument: instrument,
      execution: execution,
      currentPrice: price,
    );

    MarginCalculator.calculate(
      levels: levels,
      account: account,
      instrument: instrument,
      execution: execution,
    );

    final floatingPnl = PnlCalculator.calculateFloatingPnl(
      levels: levels,
      direction: strategy.direction,
      instrument: instrument,
      execution: execution,
      assumedPrice: price,
    );

    double totalMargin = 0;
    for (final level in levels) {
      totalMargin += level.requiredMargin;
    }

    final equity = account.equity + floatingPnl;
    final marginLevel = totalMargin > 0
        ? (equity / totalMargin) * 100
        : double.infinity;

    final drawdown = account.equity > 0
        ? ((account.equity - equity) / account.equity) * 100
        : 0.0;

    return ScenarioPoint(
      priceOffset: price - _currentPrice,
      price: price,
      triggeredLevels: levels.where((l) => l.isTriggered).length,
      drawdownPercent: drawdown.clamp(0, 100),
      marginLevelPercent: marginLevel,
      floatingPnl: floatingPnl,
      constraintsAllPassed: true,
    );
  }

  void _showInspector() {
    _inspectorController.text = _sliderValue.toStringAsFixed(2);
    setState(() => _inspectorVisible = true);
  }

  void _hideInspector() {
    setState(() => _inspectorVisible = false);
  }

  void _applyInspectorPrice() {
    final price = double.tryParse(_inspectorController.text);
    if (price != null) {
      setState(() {
        _sliderValue = price;
        _inspectorVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strategy = ref.watch(strategySpecProvider);
    final instrument = ref.watch(instrumentSpecProvider);
    final scenario = _calculateScenario(_sliderValue);
    final result = ref.watch(calculationResultProvider);

    return SafeScaffold(
      title: 'What-if Analysis',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_location),
          onPressed: _showInspector,
          tooltip: 'Quick State Inspector',
        ),
      ],
      body: Column(
        children: [
          // Quick State Inspector popup
          if (_inspectorVisible)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  const Text('Price: '),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _inspectorController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _applyInspectorPrice(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _applyInspectorPrice,
                    child: const Text('Go'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _hideInspector,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),

          // Current scenario info
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price: \$${_sliderValue.toStringAsFixed(instrument.digits > 2 ? 2 : instrument.digits)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Offset: ${(_sliderValue - _currentPrice).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: _sliderValue >= _currentPrice ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'At this price: Level ${scenario.triggeredLevels}/${strategy.levels} triggered, '
                  'Floating P/L: \$${scenario.floatingPnl.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _sliderValue,
              min: _currentPrice * 0.9, // -10%
              max: _currentPrice * 1.1, // +10%
              divisions: 200,
              label: '\$${_sliderValue.toStringAsFixed(2)}',
              onChanged: (value) {
                setState(() => _sliderValue = value);
              },
            ),
          ),

          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '-10%',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                Text(
                  '0%',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                Text(
                  '+10%',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),

          const Divider(),

          // Live metrics
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _metricTile(
                  'Triggered Levels',
                  '${scenario.triggeredLevels} / ${strategy.levels}',
                  Icons.layers,
                  scenario.triggeredLevels < strategy.levels
                      ? Colors.orange
                      : Colors.green,
                ),
                _metricTile(
                  'Drawdown',
                  '${scenario.drawdownPercent.toStringAsFixed(1)}%',
                  Icons.trending_down,
                  scenario.drawdownPercent > 30
                      ? Colors.red
                      : scenario.drawdownPercent > 15
                          ? Colors.orange
                          : Colors.green,
                ),
                _metricTile(
                  'Margin Level',
                  '${scenario.marginLevelPercent.toStringAsFixed(1)}%',
                  Icons.shield,
                  scenario.marginLevelPercent < 100
                      ? Colors.red
                      : scenario.marginLevelPercent < 200
                          ? Colors.orange
                          : Colors.green,
                ),
                _metricTile(
                  'Floating P/L',
                  '\$${scenario.floatingPnl.toStringAsFixed(2)}',
                  Icons.attach_money,
                  scenario.floatingPnl >= 0 ? Colors.green : Colors.red,
                ),

                const Divider(height: 32),

                // Constraint status
                if (result != null && result.constraintResults.isNotEmpty) ...[
                  Text(
                    'Constraint Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...result.constraintResults.map((cr) => ListTile(
                    leading: Icon(
                      cr.passed ? Icons.check_circle : Icons.cancel,
                      color: cr.passed ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    title: Text(cr.constraintName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(cr.detailMessage, style: const TextStyle(fontSize: 12)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
                ],

                const SizedBox(height: 16),

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
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
