import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../dashboard/dashboard_screen.dart';

class QuickCalculatorScreen extends ConsumerStatefulWidget {
  const QuickCalculatorScreen({super.key});

  @override
  ConsumerState<QuickCalculatorScreen> createState() =>
      _QuickCalculatorScreenState();
}

class _QuickCalculatorScreenState extends ConsumerState<QuickCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _balanceController;
  late TextEditingController _leverageController;
  late TextEditingController _stopOutController;
  late TextEditingController _initialLotController;
  late TextEditingController _multiplierController;
  late TextEditingController _distanceController;
  late TextEditingController _levelsController;
  late TextEditingController _currentPriceController;
  late TextEditingController _spreadController;
  late TextEditingController _commissionController;

  // Direction state
  Direction _direction = Direction.buy;
  
  // Advanced section expanded state
  bool _advancedExpanded = false;
  bool _constraintsExpanded = false;

  // Constraint controllers
  late TextEditingController _maxDdController;
  late TextEditingController _maxLotController;
  late TextEditingController _minMarginController;
  late TextEditingController _maxLossController;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(text: '10000');
    _leverageController = TextEditingController(text: '500');
    _stopOutController = TextEditingController(text: '20');
    _initialLotController = TextEditingController(text: '0.01');
    _multiplierController = TextEditingController(text: '1.5');
    _distanceController = TextEditingController(text: '10');
    _levelsController = TextEditingController(text: '10');
    _currentPriceController = TextEditingController(text: '3300');
    _spreadController = TextEditingController(text: '30');
    _commissionController = TextEditingController(text: '0');
    _maxDdController = TextEditingController();
    _maxLotController = TextEditingController();
    _minMarginController = TextEditingController();
    _maxLossController = TextEditingController();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _leverageController.dispose();
    _stopOutController.dispose();
    _initialLotController.dispose();
    _multiplierController.dispose();
    _distanceController.dispose();
    _levelsController.dispose();
    _currentPriceController.dispose();
    _spreadController.dispose();
    _commissionController.dispose();
    _maxDdController.dispose();
    _maxLotController.dispose();
    _minMarginController.dispose();
    _maxLossController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    // Update providers
    ref.read(accountSpecProvider.notifier).state = AccountSpec(
      balance: double.tryParse(_balanceController.text) ?? 10000,
      leverage: double.tryParse(_leverageController.text) ?? 500,
      stopOutLevelPercent: double.tryParse(_stopOutController.text) ?? 20,
    );

    ref.read(strategySpecProvider.notifier).state = StrategySpec(
      direction: _direction,
      initialLot: double.tryParse(_initialLotController.text) ?? 0.01,
      multiplier: double.tryParse(_multiplierController.text) ?? 1.5,
      fixedDistance: double.tryParse(_distanceController.text) ?? 10,
      levels: int.tryParse(_levelsController.text) ?? 10,
      roundingMode: LotRoundingMode.round,
    );

    ref.read(currentPriceProvider.notifier).state =
        double.tryParse(_currentPriceController.text) ?? 3300;

    ref.read(executionSpecProvider.notifier).state = ExecutionSpec(
      spreadPoints: double.tryParse(_spreadController.text) ?? 30,
      commissionPerLot: double.tryParse(_commissionController.text) ?? 0,
    );

    ref.read(constraintSetProvider.notifier).state = ConstraintSet(
      maxDrawdownPercent: double.tryParse(_maxDdController.text),
      maxTotalLot: double.tryParse(_maxLotController.text),
      minMarginLevelPercent: double.tryParse(_minMarginController.text),
      maxLossAmount: double.tryParse(_maxLossController.text),
    );

    // Navigate to dashboard (replace so back button returns to home)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instrument = ref.watch(instrumentSpecProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid Survival Simulator'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
            // Symbol selector
            DropdownButtonFormField<String>(
              value: instrument.symbol,
              decoration: const InputDecoration(
                labelText: 'Symbol',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'XAUUSD', child: Text('XAUUSD (Gold)')),
                DropdownMenuItem(value: 'EURUSD', child: Text('EURUSD (Euro)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(instrumentSpecProvider.notifier).state =
                      InstrumentSpec.defaults(value);
                  // Update current price
                  if (value == 'XAUUSD') {
                    _currentPriceController.text = '3300';
                  } else {
                    _currentPriceController.text = '1.08500';
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Direction selector
            _buildSectionTitle('Direction'),
            SegmentedButton<Direction>(
              segments: const [
                ButtonSegment(
                  value: Direction.buy,
                  label: Text('BUY'),
                  icon: Icon(Icons.trending_up),
                ),
                ButtonSegment(
                  value: Direction.sell,
                  label: Text('SELL'),
                  icon: Icon(Icons.trending_down),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (Set<Direction> selected) {
                setState(() {
                  _direction = selected.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Account section
            _buildSectionTitle('Account'),
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Balance (USD)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _leverageController,
              decoration: const InputDecoration(
                labelText: 'Leverage (e.g., 500 = 1:500)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stopOutController,
              decoration: const InputDecoration(
                labelText: 'Stop-out Level (%)',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Strategy section
            _buildSectionTitle('Strategy'),
            TextFormField(
              controller: _initialLotController,
              decoration: const InputDecoration(
                labelText: 'Initial Lot',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _multiplierController,
              decoration: const InputDecoration(
                labelText: 'Multiplier',
                border: OutlineInputBorder(),
                helperText: '1.0 = flat grid, >1.0 = Martingale-style',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _distanceController,
              decoration: InputDecoration(
                labelText: 'Grid Distance (${instrument.symbol == "XAUUSD" ? '\$' : "pips"})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _levelsController,
              decoration: const InputDecoration(
                labelText: 'Configured Levels',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final n = int.tryParse(v);
                if (n == null || n < 1) return 'Must be ≥ 1';
                if (n > 100) return 'Max 100 levels';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _currentPriceController,
              decoration: const InputDecoration(
                labelText: 'Current Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Advanced section (collapsed)
            ExpansionTile(
              title: const Text('Execution (Advanced)'),
              initiallyExpanded: _advancedExpanded,
              onExpansionChanged: (v) => setState(() => _advancedExpanded = v),
              children: [
                TextFormField(
                  controller: _spreadController,
                  decoration: const InputDecoration(
                    labelText: 'Spread (points)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commissionController,
                  decoration: const InputDecoration(
                    labelText: 'Commission per lot (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Constraints section (collapsed)
            ExpansionTile(
              title: const Text('Risk Constraints (Advanced)'),
              initiallyExpanded: _constraintsExpanded,
              onExpansionChanged: (v) => setState(() => _constraintsExpanded = v),
              children: [
                TextFormField(
                  controller: _maxDdController,
                  decoration: const InputDecoration(
                    labelText: 'Max Drawdown %',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 30',
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _maxLotController,
                  decoration: const InputDecoration(
                    labelText: 'Max Total Lot',
                    border: OutlineInputBorder(),
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
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Many traders use 20-30% Max DD. This is reference only, not a recommendation.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Calculate button
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
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
            ),
            const AppBannerAd(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
