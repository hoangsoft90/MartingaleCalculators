import 'package:flutter/material.dart';
import 'package:grid_engine/grid_engine.dart';

/// Displays the first constraint violation with actionable details.
///
/// Shows which constraint failed, at which level, and suggests
/// which parameter to adjust. No safety claims — just data.
class FailureExplanationPanel extends StatelessWidget {
  final ViolationDetail violation;

  const FailureExplanationPanel({super.key, required this.violation});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bottleneck: ${violation.constraintName}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Detail message
            Text(
              violation.detailMessage,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade600,
              ),
            ),

            // Level info
            if (violation.violatedLevel != null) ...[
              const SizedBox(height: 4),
              Text(
                'First violated at Level ${violation.violatedLevel}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade500,
                ),
              ),
            ],

            // Excess amount
            if (violation.excess != null && violation.excess! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Excess: ${violation.excess!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade500,
                ),
              ),
            ],

            // Suggested adjustment
            if (violation.suggestedParam != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Try adjusting: ${violation.suggestedParam}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
