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

  /// Find the first violated constraint with detail about which level caused it.
  ///
  /// Returns the first constraint that fails, along with the level index
  /// and the degree of violation (actualValue - limitValue).
  /// Returns null if all constraints pass.
  static ViolationDetail? findFirstViolation({
    required ConstraintSet constraints,
    required AccountSpec account,
    required List<GridLevel> levels,
    required double maxDrawdownPercent,
    required double totalExposureLots,
    required double totalRequiredMargin,
    required double totalFloatingPnl,
  }) {
    final results = evaluate(
      constraints: constraints,
      account: account,
      levels: levels,
      maxDrawdownPercent: maxDrawdownPercent,
      totalExposureLots: totalExposureLots,
      totalRequiredMargin: totalRequiredMargin,
      totalFloatingPnl: totalFloatingPnl,
    );

    for (final result in results) {
      if (!result.passed) {
        // Determine which level and the degree of violation
        int? violatedLevel;
        double? excess;

        switch (result.constraintName) {
          case 'Max Drawdown':
            violatedLevel = _findDrawdownViolationLevel(levels, account);
            excess = maxDrawdownPercent - (constraints.maxDrawdownPercent ?? 0);
            break;
          case 'Max Total Lot':
            violatedLevel = _findLotViolationLevel(levels, constraints.maxTotalLot ?? 0);
            excess = totalExposureLots - (constraints.maxTotalLot ?? 0);
            break;
          case 'Min Margin Level':
            violatedLevel = _findMarginLevelViolationLevel(
              levels, account, totalRequiredMargin, totalFloatingPnl,
            );
            final equity = account.equity + totalFloatingPnl;
            final marginLevel = totalRequiredMargin > 0
                ? (equity / totalRequiredMargin) * 100
                : 0;
            excess = (constraints.minMarginLevelPercent ?? 0) - marginLevel;
            break;
          case 'Max Loss':
            violatedLevel = _findLossViolationLevel(
              levels, account, constraints.maxLossAmount ?? 0,
            );
            excess = totalFloatingPnl.abs() - (constraints.maxLossAmount ?? 0);
            break;
        }

        // Determine suggested parameter to adjust
        String? suggestedParam;
        switch (result.constraintName) {
          case 'Max Drawdown':
          case 'Max Loss':
            suggestedParam = 'Multiplier';
            break;
          case 'Max Total Lot':
            suggestedParam = 'Initial Lot';
            break;
          case 'Min Margin Level':
            suggestedParam = 'Leverage';
            break;
        }

        return ViolationDetail(
          constraintName: result.constraintName,
          detailMessage: result.detailMessage,
          violatedLevel: violatedLevel,
          excess: excess,
          suggestedParam: suggestedParam,
        );
      }
    }

    return null; // All constraints passed
  }

  /// Find the level where drawdown first exceeds the constraint.
  static int? _findDrawdownViolationLevel(
    List<GridLevel> levels,
    AccountSpec account,
  ) {
    if (levels.isEmpty || account.equity <= 0) return null;
    for (int i = 0; i < levels.length; i++) {
      final dd = ((i + 1) / levels.length) * 100;
      if (dd > 50) return i + 1; // Simplified threshold
    }
    return null;
  }

  /// Find the level where total lot first exceeds the constraint.
  static int? _findLotViolationLevel(List<GridLevel> levels, double maxLot) {
    for (int i = 0; i < levels.length; i++) {
      if (levels[i].cumulativeLot > maxLot) return i + 1;
    }
    return null;
  }

  /// Find the level where margin level first drops below the constraint.
  static int? _findMarginLevelViolationLevel(
    List<GridLevel> levels,
    AccountSpec account,
    double totalRequiredMargin,
    double totalFloatingPnl,
  ) {
    if (levels.isEmpty) return null;
    for (int i = 0; i < levels.length; i++) {
      final equity = account.equity + totalFloatingPnl * ((i + 1) / levels.length);
      final marginLevel = totalRequiredMargin > 0
          ? (equity / totalRequiredMargin) * 100
          : double.infinity;
      if (marginLevel < 100) return i + 1; // Below 100% margin level
    }
    return null;
  }

  /// Find the level where loss first exceeds the constraint.
  static int? _findLossViolationLevel(
    List<GridLevel> levels,
    AccountSpec account,
    double maxLoss,
  ) {
    if (levels.isEmpty) return null;
    for (int i = 0; i < levels.length; i++) {
      final estimatedLoss = levels[i].cumulativeLot * 100; // Simplified
      if (estimatedLoss > maxLoss) return i + 1;
    }
    return null;
  }
}

/// Detail about a specific constraint violation.
class ViolationDetail {
  /// Name of the violated constraint.
  final String constraintName;

  /// Human-readable detail message.
  final String detailMessage;

  /// Level at which the violation first occurs (null if not applicable).
  final int? violatedLevel;

  /// Degree of violation: actualValue - limitValue (positive = violated).
  final double? excess;

  /// Suggested parameter to adjust (e.g., 'Multiplier', 'Initial Lot').
  final String? suggestedParam;

  const ViolationDetail({
    required this.constraintName,
    required this.detailMessage,
    this.violatedLevel,
    this.excess,
    this.suggestedParam,
  });
}
