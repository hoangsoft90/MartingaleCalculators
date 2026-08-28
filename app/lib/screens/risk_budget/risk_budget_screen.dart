import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';

class RiskBudgetScreen extends ConsumerStatefulWidget {
  const RiskBudgetScreen({super.key});

  @override
  ConsumerState<RiskBudgetScreen> createState() => _RiskBudgetScreenState();
}

class _RiskBudgetScreenState extends ConsumerState<RiskBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maxLossController = TextEditingController();
  ReverseResult? _result;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _maxLossController.dispose();
    super.dispose();
  }

  void _solve() {
    if (!_formKey.currentState!.validate()) return;

    final maxLoss = double.tryParse(_maxLossController.text);
    if (maxLoss == null || maxLoss <= 0) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a valid Max Loss amount.';
      });
      return;
    }

    final constraints = ConstraintSet(maxLossAmount: maxLoss);

    try {
      final result = ReverseSolver.solve(
        account: ref.read(accountSpecProvider),
        instrument: ref.read(instrumentSpecProvider),
        execution: ref.read(executionSpecProvider),
        strategy: ref.read(strategySpecProvider),
        constraints: constraints,
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
      title: 'Risk Budget',
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
                    'Risk Budget',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the maximum dollar amount you\'re willing to lose. '
                    'The solver will find the largest Initial Lot that keeps '
                    'your loss within this budget for a ${strategy.levels}-level '
                    '${instrument.symbol} grid.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Max Loss input
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maximum Loss (\$)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  autofocus: true,
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
