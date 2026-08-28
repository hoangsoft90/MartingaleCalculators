import '../models/account_spec.dart';
import '../models/strategy_spec.dart';
import '../models/instrument_spec.dart';
import '../models/execution_spec.dart';
import '../models/grid_level.dart';
import '../models/constraint_set.dart';
import 'grid_builder.dart';
import 'margin_calculator.dart';
import 'constraint_evaluator.dart';

/// Deterministic survival analysis.
///
/// Implements formula from spec section 3.7:
///   marginLevelPercent(n) = (equity + totalFloatingPnl(n)) / totalRequiredMargin(n) × 100
///
/// Survivable Levels = max level where marginLevelPercent > stopOutLevelPercent
/// Estimated Stop-out Price = price where marginLevelPercent hits stopOutLevel
class SurvivalEngine {
  /// Analyze survival through grid levels.
  ///
  /// Returns (survivableLevels, estimatedStopOutPrice).
  /// estimatedStopOutPrice is null if not reached within configured levels.
  static SurvivalResult analyze({
    required List<GridLevel> levels,
    required AccountSpec account,
    required StrategySpec strategy,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
  }) {
    if (levels.isEmpty) {
      return const SurvivalResult(survivableLevels: 0);
    }

    int survivableLevels = 0;
    double? estimatedStopOutPrice;
    double previousMarginLevel = double.infinity;
    double previousPrice = levels.first.entryPrice;

    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];
      final triggeredLevels = levels.sublist(0, i + 1);

      // Calculate total floating P/L for triggered levels at this level's entry
      // (conservative: assume price drops to next level's entry)
      double totalFloatingPnl = 0;
      final directionSign = strategy.direction == Direction.buy ? 1.0 : -1.0;

      // Use this level's entry as the "adverse" price
      final adversePrice = level.entryPrice;

      for (final triggered in triggeredLevels) {
        final closePrice = _getClosePrice(
          adversePrice,
          strategy.direction,
          execution.spreadPoints,
          instrument.tickSize,
        );
        final pnl = (closePrice - triggered.entryPrice) *
            directionSign *
            instrument.contractSize *
            triggered.roundedLot;
        final commission = execution.commissionPerLot * triggered.roundedLot;
        final swap = execution.swapPerLotPerDay *
            triggered.roundedLot *
            execution.holdingDays;
        totalFloatingPnl += pnl - commission - swap;
      }

      // Calculate total required margin
      double totalMargin = 0;
      for (final triggered in triggeredLevels) {
        totalMargin += triggered.requiredMargin;
      }

      // Margin Level %
      final equity = account.equity + totalFloatingPnl;
      final marginLevel = totalMargin > 0
          ? (equity / totalMargin) * 100
          : double.infinity;

      if (marginLevel > account.stopOutLevelPercent) {
        survivableLevels = i + 1;
      } else {
        // Interpolate stop-out price between this level and previous
        if (estimatedStopOutPrice == null) {
          // Handle first level case (no previous finite margin level)
          if (i == 0) {
            // First level already violates — estimate based on current price
            estimatedStopOutPrice = level.entryPrice;
          } else if (previousMarginLevel.isFinite) {
            estimatedStopOutPrice = _interpolateStopOutPrice(
              previousMarginLevel,
              marginLevel,
              previousPrice,
              level.entryPrice,
              account.stopOutLevelPercent,
            );
          } else {
            // Previous margin was infinite (no margin required) — use current level
            estimatedStopOutPrice = level.entryPrice;
          }
        }
      }

      previousMarginLevel = marginLevel;
      previousPrice = level.entryPrice;
    }

    // If all levels survived, stop-out not reached
    if (survivableLevels == levels.length) {
      estimatedStopOutPrice = null;
    }

    return SurvivalResult(
      survivableLevels: survivableLevels,
      estimatedStopOutPrice: estimatedStopOutPrice,
    );
  }

  /// Find maximum number of survivable levels.
  ///
  /// Runs the engine incrementally, stopping at the first level where
  /// any constraint fails or stop-out is reached.
  ///
  /// [upperBound] prevents infinite loops — returns with reachedUpperBound=true
  /// if all levels survive up to this limit.
  static MaxLevelsResult maxSurvivableLevels({
    required StrategySpec strategy,
    required AccountSpec account,
    required InstrumentSpec instrument,
    required ExecutionSpec execution,
    required ConstraintSet constraints,
    double currentPrice = 3300.0,
    int upperBound = 50,
  }) {
    int maxSurvived = 0;
    String? failedConstraint;

    for (int n = 1; n <= upperBound; n++) {
      // Build grid with n levels
      final testStrategy = strategy.copyWith(levels: n);
      final levels = GridBuilder.build(
        strategy: testStrategy,
        instrument: instrument,
        execution: execution,
        currentPrice: currentPrice,
      );

      MarginCalculator.calculate(
        levels: levels,
        account: account,
        instrument: instrument,
        execution: execution,
      );

      // Check survival
      final survival = analyze(
        levels: levels,
        account: account,
        strategy: testStrategy,
        instrument: instrument,
        execution: execution,
      );

      if (survival.survivableLevels < n) {
        failedConstraint = 'Stop-out reached';
        break;
      }

      // Check constraints
      double totalMargin = 0;
      double totalLot = 0;
      for (final level in levels) {
        totalMargin += level.requiredMargin;
        totalLot += level.roundedLot;
      }

      final constraintResults = ConstraintEvaluator.evaluate(
        constraints: constraints,
        account: account,
        levels: levels,
        maxDrawdownPercent: 0,
        totalExposureLots: totalLot,
        totalRequiredMargin: totalMargin,
        totalFloatingPnl: 0,
      );

      final firstViolation = constraintResults.firstWhere(
        (r) => !r.passed,
        orElse: () => const ConstraintCheckResult(
          constraintName: '',
          passed: true,
          detailMessage: '',
        ),
      );

      if (!firstViolation.passed) {
        failedConstraint = firstViolation.constraintName;
        break;
      }

      maxSurvived = n;
    }

    return MaxLevelsResult(
      maxLevels: maxSurvived,
      reachedUpperBound: maxSurvived == upperBound,
      failedConstraint: failedConstraint,
    );
  }

  /// Interpolate stop-out price between two levels.
  static double _interpolateStopOutPrice(
    double prevMarginLevel,
    double currMarginLevel,
    double prevPrice,
    double currPrice,
    double stopOutLevel,
  ) {
    if (prevMarginLevel == currMarginLevel) return currPrice;
    if (!prevMarginLevel.isFinite || !currMarginLevel.isFinite) return currPrice;

    final t = (stopOutLevel - prevMarginLevel) /
        (currMarginLevel - prevMarginLevel);
    return prevPrice + t * (currPrice - prevPrice);
  }

  /// Get close price for P/L calculation.
  static double _getClosePrice(
    double assumedPrice,
    Direction direction,
    double spreadPoints,
    double tickSize,
  ) {
    final halfSpread = (spreadPoints / 2) * tickSize;
    switch (direction) {
      case Direction.buy:
        return assumedPrice - halfSpread;
      case Direction.sell:
        return assumedPrice + halfSpread;
    }
  }
}

/// Result of survival analysis.
class SurvivalResult {
  final int survivableLevels;
  final double? estimatedStopOutPrice;

  const SurvivalResult({
    required this.survivableLevels,
    this.estimatedStopOutPrice,
  });
}

/// Result of max levels analysis.
class MaxLevelsResult {
  /// Maximum number of levels that survive all constraints.
  final int maxLevels;

  /// Whether the upper bound was reached (may need more levels).
  final bool reachedUpperBound;

  /// The constraint that failed at the first non-survivable level.
  final String? failedConstraint;

  const MaxLevelsResult({
    required this.maxLevels,
    this.reachedUpperBound = false,
    this.failedConstraint,
  });
}
