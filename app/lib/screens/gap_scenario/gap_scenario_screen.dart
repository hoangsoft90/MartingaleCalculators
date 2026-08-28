import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';

class GapScenarioScreen extends ConsumerStatefulWidget {
  const GapScenarioScreen({super.key});

  @override
  ConsumerState<GapScenarioScreen> createState() => _GapScenarioScreenState();
}

class _GapScenarioScreenState extends ConsumerState<GapScenarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gapPriceController = TextEditingController();
  bool _isAtMarket = false;

  @override
  void dispose() {
    _gapPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strategy = ref.watch(strategySpecProvider);
    final instrument = ref.watch(instrumentSpecProvider);
    final currentPrice = ref.watch(currentPriceProvider);

    return SafeScaffold(
      title: 'Gap Scenario',
      showBannerAd: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Explanation
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gap Scenario Analysis',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simulate what happens when price gaps past multiple grid levels '
                    'in a single move (e.g., weekend gap, news event).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gap price input
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gap Target Price',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _gapPriceController,
                  decoration: InputDecoration(
                    labelText: 'Price after gap',
                    border: const OutlineInputBorder(),
                    hintText: 'e.g., ${currentPrice.toStringAsFixed(2)}',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Execution mode toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Execution Mode',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAtMarket
                                ? 'At Market: All levels in gap trigger at same price'
                                : 'Sequential: Each level triggers at its own entry price',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAtMarket,
                      onChanged: (value) => setState(() => _isAtMarket = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Analyze button
          FilledButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Analysis will be shown below
                setState(() {});
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Analyze Gap'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),

          // Results (when gap price is entered)
          if (_gapPriceController.text.isNotEmpty)
            Builder(
              builder: (context) {
                final gapPrice = double.tryParse(_gapPriceController.text);
                if (gapPrice == null) return const SizedBox.shrink();

                final executionMode = _isAtMarket
                    ? ExecutionMode.atMarket
                    : ExecutionMode.sequential;

                // Build levels for gap scenario
                final execution = ref.read(executionSpecProvider).copyWith(
                  executionMode: executionMode,
                );

                final levels = GridBuilder.build(
                  strategy: strategy,
                  instrument: instrument,
                  execution: execution,
                  currentPrice: currentPrice,
                );

                // Find levels that would be triggered in the gap
                final triggeredLevels = <GridLevel>[];
                for (final level in levels) {
                  if (strategy.direction == Direction.buy) {
                    if (level.entryPrice >= gapPrice) {
                      triggeredLevels.add(level);
                    }
                  } else {
                    if (level.entryPrice <= gapPrice) {
                      triggeredLevels.add(level);
                    }
                  }
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gap Analysis Results',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _resultRow('Current Price', '\$${currentPrice.toStringAsFixed(2)}'),
                        _resultRow('Gap Target', '\$${gapPrice.toStringAsFixed(2)}'),
                        _resultRow('Execution Mode', _isAtMarket ? 'At Market' : 'Sequential'),
                        const Divider(),
                        _resultRow(
                          'Levels Triggered',
                          '${triggeredLevels.length} / ${strategy.levels}',
                        ),
                        if (triggeredLevels.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Triggered Levels:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...triggeredLevels.map((l) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text(
                              'Level ${l.index}: ${l.roundedLot.toStringAsFixed(2)} lots @ \$${l.entryPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Actual execution may differ due to broker/order execution behavior.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
