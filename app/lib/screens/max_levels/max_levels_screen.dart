import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';

class MaxLevelsScreen extends ConsumerStatefulWidget {
  const MaxLevelsScreen({super.key});

  @override
  ConsumerState<MaxLevelsScreen> createState() => _MaxLevelsScreenState();
}

class _MaxLevelsScreenState extends ConsumerState<MaxLevelsScreen> {
  MaxLevelsResult? _result;
  bool _hasError = false;
  String _errorMessage = '';

  void _solve() {
    try {
      final result = SurvivalEngine.maxSurvivableLevels(
        strategy: ref.read(strategySpecProvider),
        account: ref.read(accountSpecProvider),
        instrument: ref.read(instrumentSpecProvider),
        execution: ref.read(executionSpecProvider),
        constraints: ref.read(constraintSetProvider),
        currentPrice: ref.read(currentPriceProvider),
      );

      setState(() {
        _result = result;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final instrument = ref.watch(instrumentSpecProvider);
    final strategy = ref.watch(strategySpecProvider);

    return SafeScaffold(
      title: 'Max Levels Solver',
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
                    'How it works',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This solver finds the maximum number of grid levels '
                    'your account can support before hitting stop-out or '
                    'violating any constraint.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current config
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Configuration',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Symbol: ${instrument.symbol}'),
                  Text('Direction: ${strategy.direction.name.toUpperCase()}'),
                  Text('Initial Lot: ${strategy.initialLot}'),
                  Text('Multiplier: ${strategy.multiplier}'),
                  Text('Distance: ${strategy.fixedDistance}'),
                  Text('Configured Levels: ${strategy.levels}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Solve button
          FilledButton.icon(
            onPressed: _solve,
            icon: const Icon(Icons.calculate),
            label: const Text('Find Maximum Survivable Levels'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),

          // Error
          if (_hasError)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Result
          if (_result != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Maximum Survivable Levels',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_result!.maxLevels}',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'out of ${strategy.levels} configured',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Status
            if (_result!.reachedUpperBound)
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: Icon(Icons.info, color: Colors.orange.shade700),
                  title: const Text('Reached Upper Bound'),
                  subtitle: const Text(
                    'All levels survived. Try increasing upper bound for more.',
                  ),
                ),
              ),

            if (_result!.failedConstraint != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.orange),
                  title: const Text('First Failure'),
                  subtitle: Text(_result!.failedConstraint!),
                ),
              ),

            // Comparison
            if (_result!.maxLevels < strategy.levels)
              Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: Icon(Icons.compare_arrows, color: Colors.red.shade700),
                  title: Text(
                    'Warning: ${strategy.levels} configured levels exceed '
                    'maximum survivable ${_result!.maxLevels} levels',
                  ),
                  subtitle: const Text(
                    'Consider reducing levels or increasing account balance.',
                  ),
                ),
              ),
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
    );
  }
}
