import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../persistence/hive_repository.dart';
import '../../state/strategy_provider.dart';
import '../../widgets/safe_scaffold.dart';
import '../dashboard/dashboard_screen.dart';

class SavedStrategiesScreen extends ConsumerStatefulWidget {
  const SavedStrategiesScreen({super.key});

  @override
  ConsumerState<SavedStrategiesScreen> createState() => _SavedStrategiesScreenState();
}

class _SavedStrategiesScreenState extends ConsumerState<SavedStrategiesScreen> {
  List<SavedStrategy> _strategies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    final strategies = await HiveRepository.loadAll();
    setState(() {
      _strategies = strategies;
      _loading = false;
    });
  }

  Future<void> _saveCurrent() async {
    final nameController = TextEditingController();
    
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Strategy'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Strategy Name',
            hintText: 'e.g., XAUUSD Conservative',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      final strategy = ref.read(strategySpecProvider);
      final instrument = ref.read(instrumentSpecProvider);
      final execution = ref.read(executionSpecProvider);
      final account = ref.read(accountSpecProvider);
      final price = ref.read(currentPriceProvider);
      final constraints = ref.read(constraintSetProvider);

      await HiveRepository.saveStrategy(
        name: name,
        strategy: strategy,
        instrument: instrument,
        execution: execution,
        account: account,
        currentPrice: price,
        constraints: constraints,
      );

      await _loadStrategies();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Strategy saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadStrategy(SavedStrategy saved) async {
    ref.read(strategySpecProvider.notifier).state = saved.strategy;
    ref.read(instrumentSpecProvider.notifier).state = saved.instrument;
    ref.read(executionSpecProvider.notifier).state = saved.execution;
    ref.read(accountSpecProvider.notifier).state = saved.account;
    ref.read(currentPriceProvider.notifier).state = saved.currentPrice;
    ref.read(constraintSetProvider.notifier).state = saved.constraints;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Future<void> _deleteStrategy(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Strategy?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HiveRepository.deleteStrategy(index);
      await _loadStrategies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      title: 'Saved Strategies',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _saveCurrent,
          tooltip: 'Save current',
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _strategies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No saved strategies',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to save your current strategy',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _strategies.length,
                  itemBuilder: (context, index) {
                    final s = _strategies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          '${s.instrument.symbol} | ${s.strategy.direction.name.toUpperCase()} | '
                          '${s.strategy.initialLot} lot × ${s.strategy.multiplier} | '
                          '${s.strategy.levels} levels',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('dd/MM HH:mm').format(s.timestamp),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteStrategy(s.index),
                            ),
                          ],
                        ),
                        onTap: () => _loadStrategy(s),
                      ),
                    );
                  },
                ),
    );
  }
}
