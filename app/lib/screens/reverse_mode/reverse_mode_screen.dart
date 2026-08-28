import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';

class ReverseModeScreen extends ConsumerStatefulWidget {
  const ReverseModeScreen({super.key});

  @override
  ConsumerState<ReverseModeScreen> createState() => _ReverseModeScreenState();
}

class _ReverseModeScreenState extends ConsumerState<ReverseModeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _maxDdController;
  late TextEditingController _minMarginController;
  late TextEditingController _maxLotController;
  late TextEditingController _maxLossController;
  
  ReverseResult? _result;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final constraints = ref.read(constraintSetProvider);
    _maxDdController = TextEditingController(
      text: constraints.maxDrawdownPercent?.toString() ?? '',
    );
    _minMarginController = TextEditingController(
      text: constraints.minMarginLevelPercent?.toString() ?? '',
    );
    _maxLotController = TextEditingController(
      text: constraints.maxTotalLot?.toString() ?? '',
    );
    _maxLossController = TextEditingController(
      text: constraints.maxLossAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _maxDdController.dispose();
    _minMarginController.dispose();
    _maxLotController.dispose();
    _maxLossController.dispose();
    super.dispose();
  }

  void _solve() {
    if (!_formKey.currentState!.validate()) return;

    final constraints = ConstraintSet(
      maxDrawdownPercent: double.tryParse(_maxDdController.text),
      maxTotalLot: double.tryParse(_maxLotController.text),
      minMarginLevelPercent: double.tryParse(_minMarginController.text),
      maxLossAmount: double.tryParse(_maxLossController.text),
    );

    if (!constraints.hasAny) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter at least one constraint.';
      });
      return;
    }

    try {
      final result = ReverseSolver.solve(
        account: ref.read(accountSpecProvider),
        instrument: ref.read(instrumentSpecProvider),
        execution: ref.read(executionSpecProvider),
        strategy: ref.read(strategySpecProvider),
        constraints: constraints,
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
      title: 'Reverse Mode',
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
                    'Enter at least one risk constraint. The solver will find the '
                    'Maximum Initial Lot that satisfies all constraints for your '
                    '${strategy.levels}-level ${instrument.symbol} grid.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current config display
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
                  Text('Multiplier: ${strategy.multiplier}'),
                  Text('Distance: ${strategy.fixedDistance}'),
                  Text('Levels: ${strategy.levels}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Constraint inputs
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Constraints (at least 1 required)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _maxDdController,
                  decoration: const InputDecoration(
                    labelText: 'Max Drawdown %',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                    hintText: 'e.g., 30',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minMarginController,
                  decoration: const InputDecoration(
                    labelText: 'Min Margin Level %',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                    hintText: 'e.g., 100',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _maxLotController,
                  decoration: const InputDecoration(
                    labelText: 'Max Total Lot',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 1.0',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _maxLossController,
                  decoration: const InputDecoration(
                    labelText: 'Max Loss (\$)',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                    hintText: 'e.g., 500',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Solve button
          FilledButton.icon(
            onPressed: _solve,
            icon: const Icon(Icons.calculate),
            label: const Text('Find Maximum Initial Lot'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),

          // Error message
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
                      'Maximum Initial Lot',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.maximumInitialLot.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Binary search converged in ${_result!.iterations} iterations',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bottleneck
            if (_result!.bottleneckConstraint != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.orange),
                  title: const Text('Bottleneck Constraint'),
                  subtitle: Text(_result!.bottleneckConstraint!.detailMessage),
                ),
              ),

            // All results
            ExpansionTile(
              title: const Text('All Constraint Results'),
              children: _result!.allResults
                  .map((cr) => ListTile(
                        leading: Icon(
                          cr.passed ? Icons.check_circle : Icons.cancel,
                          color: cr.passed ? Colors.green : Colors.red,
                        ),
                        title: Text(cr.constraintName),
                        subtitle: Text(cr.detailMessage),
                        dense: true,
                      ))
                  .toList(),
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
