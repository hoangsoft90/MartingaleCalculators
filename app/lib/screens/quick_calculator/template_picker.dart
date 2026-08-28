import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grid_engine/grid_engine.dart';
import '../../data/strategy_templates.dart';
import '../../state/strategy_provider.dart';

/// Template picker that shows strategy presets with risk preview.
///
/// When a template is selected, it shows the multiplier and a quick
/// risk preview (survivable levels / total) before the user confirms.
class TemplatePicker extends ConsumerWidget {
  const TemplatePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strategy Templates',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...StrategyTemplates.all.map((template) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.speed,
                  color: template.strategy.multiplier <= 1.2
                      ? Colors.green
                      : template.strategy.multiplier <= 1.5
                          ? Colors.orange
                          : Colors.red,
                ),
                title: Text(template.name),
                subtitle: Text(template.description),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _applyTemplate(context, ref, template),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _applyTemplate(BuildContext context, WidgetRef ref, StrategyTemplate template) {
    // Show confirmation dialog with risk preview
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(template.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.description),
            const SizedBox(height: 16),
            _previewRow('Multiplier', '${template.strategy.multiplier}x'),
            _previewRow('Initial Lot', '${template.strategy.initialLot}'),
            _previewRow('Distance', '${template.strategy.fixedDistance}'),
            _previewRow('Levels', '${template.strategy.levels}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(strategySpecProvider.notifier).state = template.strategy;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Applied: ${template.name}')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
