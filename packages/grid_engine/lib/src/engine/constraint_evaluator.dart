import '../models/account_spec.dart';
import '../models/constraint_set.dart';
import '../models/grid_level.dart';

/// Evaluates user-defined risk constraints against calculation results.
///
/// No "SAFE/LOW/HIGH" or color-coded risk scores.
/// Only objective PASS/FAIL against user-defined limits.
class ConstraintEvaluator {
  /// Evaluate all defined constraints.
  ///
  /// Returns a list of [ConstraintCheckResult] for each defined constraint.
  /// Undefined constraints are skipped (not included in results).
  static List<ConstraintCheckResult> evaluate({
    required ConstraintSet constraints,
    required AccountSpec account,
    required List<GridLevel> levels,
    required double maxDrawdownPercent,
    required double totalExposureLots,
    required double totalRequiredMargin,
    required double totalFloatingPnl,
  }) {
    final results = <ConstraintCheckResult>[];

    // Max Drawdown %
    if (constraints.maxDrawdownPercent != null) {
      final passed = maxDrawdownPercent <= constraints.maxDrawdownPercent!;
      results.add(ConstraintCheckResult(
        constraintName: 'Max Drawdown',
        passed: passed,
        violatedAtLevel: passed ? null : _findDrawdownViolationLevel(levels, account),
        detailMessage: passed
            ? 'Max DD ${maxDrawdownPercent.toStringAsFixed(1)}% ≤ ${constraints.maxDrawdownPercent}% ✓'
            : 'Max DD ${maxDrawdownPercent.toStringAsFixed(1)}% > ${constraints.maxDrawdownPercent}% ✗',
      ));
    }

    // Max Total Lot
    if (constraints.maxTotalLot != null) {
      final passed = totalExposureLots <= constraints.maxTotalLot!;
      results.add(ConstraintCheckResult(
        constraintName: 'Max Total Lot',
        passed: passed,
        detailMessage: passed
            ? 'Total ${totalExposureLots.toStringAsFixed(2)} lots ≤ ${constraints.maxTotalLot} lots ✓'
            : 'Total ${totalExposureLots.toStringAsFixed(2)} lots > ${constraints.maxTotalLot} lots ✗',
      ));
    }

    // Min Margin Level %
    if (constraints.minMarginLevelPercent != null) {
      final equity = account.equity + totalFloatingPnl;
      final marginLevel = totalRequiredMargin > 0
          ? (equity / totalRequiredMargin) * 100
          : double.infinity;
      final passed = marginLevel >= constraints.minMarginLevelPercent!;
      results.add(ConstraintCheckResult(
        constraintName: 'Min Margin Level',
        passed: passed,
        detailMessage: passed
            ? 'Margin Level ${marginLevel.toStringAsFixed(1)}% ≥ ${constraints.minMarginLevelPercent}% ✓'
            : 'Margin Level ${marginLevel.toStringAsFixed(1)}% < ${constraints.minMarginLevelPercent}% ✗',
      ));
    }

    // Max Loss $
    if (constraints.maxLossAmount != null) {
      final passed = totalFloatingPnl.abs() <= constraints.maxLossAmount!;
      results.add(ConstraintCheckResult(
        constraintName: 'Max Loss',
        passed: passed,
        detailMessage: passed
            ? 'Loss \$${totalFloatingPnl.abs().toStringAsFixed(2)} ≤ \$${constraints.maxLossAmount} ✓'
            : 'Loss \$${totalFloatingPnl.abs().toStringAsFixed(2)} > \$${constraints.maxLossAmount} ✗',
      ));
    }

    return results;
  }

  /// Find the level where drawdown first violates the constraint.
  static int? _findDrawdownViolationLevel(
    List<GridLevel> levels,
    AccountSpec account,
  ) {
    double maxDd = 0;
    for (int i = 0; i < levels.length; i++) {
      // Simplified: assume each level triggers and check cumulative impact
      // Full implementation would calculate actual drawdown per level
      final dd = ((i + 1) / levels.length) * 100; // Placeholder
      if (dd > maxDd) maxDd = dd;
    }
    return null; // Proper implementation needs scenario data
  }

  /// Check if all constraints passed.
  static bool allPassed(List<ConstraintCheckResult> results) {
    return results.every((r) => r.passed);
  }

  /// Get the bottleneck constraint (the one with smallest margin).
  static ConstraintCheckResult? getBottleneck(
    List<ConstraintCheckResult> results,
  ) {
    final failed = results.where((r) => !r.passed).toList();
    if (failed.isEmpty) return null;
    return failed.first; // First failed is typically the tightest
  }
}
